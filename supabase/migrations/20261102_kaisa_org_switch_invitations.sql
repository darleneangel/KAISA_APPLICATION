-- KAISA Account Switching + Organization Staff Invitations V1
-- Requires organizations, memberships, entitlements, resident_profiles, org-admin MVP.
-- Run only after reviewing existing schema, with a database backup.
create extension if not exists pgcrypto;
create table if not exists public.kaisa_org_staff_invitations (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.kaisa_organizations(id) on delete cascade,
 invited_user_id uuid not null references auth.users(id) on delete cascade,
 invited_by uuid not null references auth.users(id),
 proposed_role text not null check (proposed_role in ('Officer','Admin')),
 note text not null default '' check (char_length(note)<=500),
 status text not null default 'pending' check(status in ('pending','declined','pending_superadmin','approved','rejected','cancelled','expired')),
 created_at timestamptz not null default now(), expires_at timestamptz not null default(now()+interval '7 days'),
 responded_at timestamptz, reviewed_by uuid references auth.users(id), reviewed_at timestamptz,
 constraint kaisa_org_invite_no_self check(invited_user_id <> invited_by)
);
create unique index if not exists kaisa_org_invites_one_open on public.kaisa_org_staff_invitations(organization_id,invited_user_id) where status in ('pending','pending_superadmin');
create index if not exists kaisa_org_invites_recipient on public.kaisa_org_staff_invitations(invited_user_id,created_at desc);
alter table public.kaisa_org_staff_invitations enable row level security;
revoke all on public.kaisa_org_staff_invitations from anon,authenticated;
grant select on public.kaisa_org_staff_invitations to authenticated;
-- Recipients see their invitations; admins see invitations scoped to organizations they manage.
drop policy if exists kaisa_org_invite_select on public.kaisa_org_staff_invitations;
create policy kaisa_org_invite_select on public.kaisa_org_staff_invitations for select to authenticated
 using(invited_user_id=(select auth.uid()) or exists (
 select 1 from public.kaisa_organization_memberships m where m.organization_id=public.kaisa_org_staff_invitations.organization_id
 and m.user_id=(select auth.uid()) and m.status='approved' and m.role='Admin'));

-- Returns only switchable organizations. No separate account or new login.
create or replace function public.kaisa_my_managed_organizations()
returns jsonb language sql stable security definer set search_path='' as $$
select coalesce(jsonb_agg(jsonb_build_object('id',o.id,'name',o.name,'role',m.role,'category',o.category)
 order by o.name),'[]'::jsonb)
from public.kaisa_organization_memberships m join public.kaisa_organizations o on o.id=m.organization_id
where m.user_id=auth.uid() and m.status='approved' and m.role in ('Admin','Officer') and o.status='published';
$$;

-- Search by name (minimum 3 chars) OR exact email. Never expose the email in results.
-- Only authorized Org Admins may search, and users must be Tier 2.
create or replace function public.kaisa_org_invite_search(p_organization_id uuid,p_query text)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare v_q text:=trim(coalesce(p_query,''));
begin
 if not public.kaisa_admin_is_allowed(p_organization_id) then raise exception 'KAISA_ADMIN_REQUIRED'; end if;
 if char_length(v_q)<3 or char_length(v_q)>120 then return '[]'::jsonb; end if;
 return coalesce((select jsonb_agg(row_to_json(t)::jsonb) from (
  select p.user_id,trim(concat_ws(' ',p.first_name,p.last_name)) as full_name,p.avatar_path
  from public.resident_profiles p join auth.users u on u.id=p.user_id
  where public.kaisa_is_tier2(p.user_id) and p.user_id<>auth.uid()
    and (lower(trim(concat_ws(' ',p.first_name,p.last_name))) like '%'||replace(replace(lower(v_q),'%','\%'),'_','\_')||'%' escape '\'
         or lower(u.email)=lower(v_q))
    and not exists (select 1 from public.kaisa_organization_memberships m
       where m.organization_id=p_organization_id and m.user_id=p.user_id and m.status='approved' and m.role in ('Officer','Admin'))
  order by p.last_name,p.first_name limit 10
 ) t),'[]'::jsonb);
end $$;

create or replace function public.kaisa_org_send_staff_invite(
 p_organization_id uuid,p_user_id uuid,p_role text,p_note text default '')
returns uuid language plpgsql security definer set search_path='' as $$
declare v_id uuid;
begin
 if not public.kaisa_admin_is_allowed(p_organization_id) then raise exception 'KAISA_ADMIN_REQUIRED'; end if;
 if p_role not in ('Officer','Admin') then raise exception 'KAISA_INVALID_ROLE'; end if;
 if not public.kaisa_is_tier2(p_user_id) then raise exception 'KAISA_INVITEE_TIER2_REQUIRED'; end if;
 if p_user_id=auth.uid() then raise exception 'KAISA_CANNOT_INVITE_SELF'; end if;
 if char_length(coalesce(p_note,''))>500 then raise exception 'KAISA_NOTE_TOO_LONG'; end if;
 if exists(select 1 from public.kaisa_organization_memberships m
   where m.organization_id=p_organization_id and m.user_id=p_user_id
   and m.status='approved' and m.role in ('Admin','Officer')) then
   raise exception 'KAISA_ALREADY_STAFF'; end if;
 -- Allow replacement only for expired invitations; no duplicate active invites.
 update public.kaisa_org_staff_invitations set status='expired'
 where organization_id=p_organization_id and invited_user_id=p_user_id
 and status='pending' and expires_at<=now();
 insert into public.kaisa_org_staff_invitations(organization_id,invited_user_id,invited_by,proposed_role,note)
 values(p_organization_id,p_user_id,auth.uid(),p_role,coalesce(p_note,'')) returning id into v_id;
 return v_id;
end $$;

create or replace function public.kaisa_my_staff_invitations()
returns jsonb language sql stable security definer set search_path='' as $$
select coalesce(jsonb_agg(jsonb_build_object(
 'id',i.id,'organization_id',i.organization_id,'organization_name',o.name,
 'role',i.proposed_role,'note',i.note,'status',i.status,'created_at',i.created_at,'expires_at',i.expires_at)
 order by i.created_at desc),'[]'::jsonb)
from public.kaisa_org_staff_invitations i join public.kaisa_organizations o on o.id=i.organization_id
where i.invited_user_id=auth.uid() and i.status in ('pending','pending_superadmin');
$$;

create or replace function public.kaisa_org_respond_staff_invite(p_invitation_id uuid,p_accept boolean)
returns text language plpgsql security definer set search_path='' as $$
declare i public.kaisa_org_staff_invitations%rowtype;
begin
 select * into i from public.kaisa_org_staff_invitations where id=p_invitation_id for update;
 if not found or i.invited_user_id is distinct from auth.uid() then raise exception 'KAISA_INVITATION_NOT_FOUND'; end if;
 if i.status<>'pending' then raise exception 'KAISA_INVITATION_NOT_PENDING'; end if;
 if i.expires_at<=now() then
  update public.kaisa_org_staff_invitations set status='expired' where id=i.id;
  return 'expired';
 end if;
 if not p_accept then
  update public.kaisa_org_staff_invitations set status='declined',responded_at=now() where id=i.id;
  return 'declined';
 end if;
 if not public.kaisa_is_tier2(auth.uid()) then raise exception 'KAISA_TIER2_REQUIRED'; end if;
 if i.proposed_role='Admin' then
  update public.kaisa_org_staff_invitations set status='pending_superadmin',responded_at=now() where id=i.id;
  return 'pending_superadmin';
 end if;
 -- Officer invitations activate only after acceptance; never downgrade an existing Admin.
 insert into public.kaisa_organization_memberships(organization_id,user_id,role,status,reviewed_at,reviewed_by)
 values(i.organization_id,auth.uid(),'Officer','approved',now(),i.invited_by)
 on conflict(organization_id,user_id) do update
 set role='Officer',status='approved',reviewed_at=now(),reviewed_by=i.invited_by
 where public.kaisa_organization_memberships.role<>'Admin';
 update public.kaisa_org_staff_invitations set status='approved',responded_at=now() where id=i.id;
 return 'approved';
end $$;

-- Super Admin only: approve/reject accepted invitations requesting Admin role.
create or replace function public.kaisa_superadmin_review_org_invite(p_invitation_id uuid,p_approve boolean)
returns void language plpgsql security definer set search_path='' as $$
declare i public.kaisa_org_staff_invitations%rowtype;
begin
 if not exists(select 1 from public.kaisa_entitlements e where e.user_id=auth.uid() and e.is_super_admin=true)
 then raise exception 'KAISA_SUPERADMIN_REQUIRED'; end if;
 select * into i from public.kaisa_org_staff_invitations where id=p_invitation_id for update;
 if not found or i.status<>'pending_superadmin' or i.proposed_role<>'Admin' then
 raise exception 'KAISA_INVITATION_NOT_AWAITING_REVIEW'; end if;
 if p_approve and not public.kaisa_is_tier2(i.invited_user_id) then raise exception 'KAISA_INVITEE_TIER2_REQUIRED'; end if;
 if p_approve then
  insert into public.kaisa_organization_memberships(organization_id,user_id,role,status,reviewed_at,reviewed_by)
  values(i.organization_id,i.invited_user_id,'Admin','approved',now(),auth.uid())
  on conflict(organization_id,user_id) do update
  set role='Admin',status='approved',reviewed_at=now(),reviewed_by=auth.uid();
 end if;
 update public.kaisa_org_staff_invitations
 set status=case when p_approve then 'approved' else 'rejected' end,reviewed_at=now(),reviewed_by=auth.uid()
 where id=i.id;
end $$;

revoke all on function public.kaisa_my_managed_organizations(),public.kaisa_org_invite_search(uuid,text),
 public.kaisa_org_send_staff_invite(uuid,uuid,text,text),public.kaisa_my_staff_invitations(),
 public.kaisa_org_respond_staff_invite(uuid,boolean),public.kaisa_superadmin_review_org_invite(uuid,boolean)
 from public,anon;
grant execute on function public.kaisa_my_managed_organizations(),public.kaisa_org_invite_search(uuid,text),
 public.kaisa_org_send_staff_invite(uuid,uuid,text,text),public.kaisa_my_staff_invitations(),
 public.kaisa_org_respond_staff_invite(uuid,boolean),public.kaisa_superadmin_review_org_invite(uuid,boolean)
 to authenticated;
