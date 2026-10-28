-- KAISA Organizations v1. Requires Community/Tier 2 migration.
-- LGU creates/publishes organizations; resident proposals never auto-publish.
-- Review existing policy names before using in a populated production database.
create extension if not exists pgcrypto;
create table if not exists public.kaisa_organizations (
 id uuid primary key default gen_random_uuid(),
 name text not null check (char_length(btrim(name)) between 3 and 150),
 category text not null default 'Community',
 description text not null default '',
 mission text not null default '',
 contact_email text,
 location text,
 status text not null default 'draft' check (status in ('draft','published','archived')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create unique index if not exists kaisa_organizations_name_unique on public.kaisa_organizations(lower(name));
create index if not exists kaisa_organizations_published_idx on public.kaisa_organizations(name) where status='published';
create table if not exists public.kaisa_organization_memberships (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.kaisa_organizations(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 role text not null default 'Member' check (role in ('Member','Officer','Admin')),
 status text not null default 'pending' check (status in ('pending','approved','rejected','withdrawn')),
 requested_at timestamptz not null default now(),
 reviewed_at timestamptz,
 reviewed_by uuid references auth.users(id),
 unique(organization_id,user_id)
);
create index if not exists kaisa_org_member_user_idx on public.kaisa_organization_memberships(user_id,status);
create table if not exists public.kaisa_organization_proposals (
 id uuid primary key default gen_random_uuid(),
 requester_id uuid not null references auth.users(id) on delete cascade,
 name text not null check (char_length(btrim(name)) between 3 and 150),
 category text not null,
 description text not null check (char_length(btrim(description)) >= 20),
 mission text not null,
 representative_name text not null,
 reason text not null check (char_length(btrim(reason)) >= 30),
 status text not null default 'pending' check (status in ('pending','approved','rejected')),
 created_at timestamptz not null default now(),
 reviewed_at timestamptz,
 reviewed_by uuid references auth.users(id),
 review_note text
);
create index if not exists kaisa_org_proposal_requester_idx on public.kaisa_organization_proposals(requester_id,created_at desc);

alter table public.kaisa_organizations enable row level security;
alter table public.kaisa_organization_memberships enable row level security;
alter table public.kaisa_organization_proposals enable row level security;
revoke all on public.kaisa_organizations,public.kaisa_organization_memberships,public.kaisa_organization_proposals from anon,authenticated;
grant select on public.kaisa_organizations,public.kaisa_organization_memberships,public.kaisa_organization_proposals to authenticated;

drop policy if exists kaisa_org_read_published on public.kaisa_organizations;
create policy kaisa_org_read_published on public.kaisa_organizations for select to authenticated using (status='published');
drop policy if exists kaisa_org_member_read_own on public.kaisa_organization_memberships;
create policy kaisa_org_member_read_own on public.kaisa_organization_memberships for select to authenticated using (user_id=(select auth.uid()));
drop policy if exists kaisa_org_proposal_read_own on public.kaisa_organization_proposals;
create policy kaisa_org_proposal_read_own on public.kaisa_organization_proposals for select to authenticated using (requester_id=(select auth.uid()));
-- No resident direct insert/update/delete privileges. Operations pass through RPCs.

create or replace function public.kaisa_organizations_catalog()
returns jsonb language sql stable security definer set search_path='' as $$
 select coalesce(jsonb_agg(jsonb_build_object(
  'id',o.id,'name',o.name,'category',o.category,'description',o.description,
  'mission',o.mission,'contact_email',o.contact_email,'location',o.location,
  'member_count',(select count(*) from public.kaisa_organization_memberships m
    where m.organization_id=o.id and m.status='approved'),
  'my_status',(select m.status from public.kaisa_organization_memberships m
    where m.organization_id=o.id and m.user_id=(select auth.uid())),
  'my_role',(select m.role from public.kaisa_organization_memberships m
    where m.organization_id=o.id and m.user_id=(select auth.uid()))
 ) order by o.name), '[]'::jsonb)
 from public.kaisa_organizations o where o.status='published';
$$;

create or replace function public.kaisa_join_organization(p_organization_id uuid)
returns void language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=auth.uid(); v_status text;
begin
 if v_uid is null then raise exception 'KAISA_LOGIN_REQUIRED'; end if;
 if not public.kaisa_is_tier2(v_uid) then raise exception 'KAISA_TIER2_REQUIRED'; end if;
 if not exists(select 1 from public.kaisa_organizations where id=p_organization_id and status='published') then
  raise exception 'KAISA_ORGANIZATION_UNAVAILABLE'; end if;
 select status into v_status from public.kaisa_organization_memberships
   where organization_id=p_organization_id and user_id=v_uid for update;
 if v_status in ('approved','pending') then raise exception 'KAISA_MEMBERSHIP_EXISTS'; end if;
 insert into public.kaisa_organization_memberships(organization_id,user_id,role,status,requested_at,reviewed_at,reviewed_by)
 values(p_organization_id,v_uid,'Member','pending',now(),null,null)
 on conflict(organization_id,user_id) do update
 set role='Member',status='pending',requested_at=now(),reviewed_at=null,reviewed_by=null;
end;
$$;

create or replace function public.kaisa_withdraw_organization(p_organization_id uuid)
returns void language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=auth.uid();
begin
 if v_uid is null then raise exception 'KAISA_LOGIN_REQUIRED'; end if;
 update public.kaisa_organization_memberships
 set status='withdrawn',reviewed_at=null,reviewed_by=null
 where organization_id=p_organization_id and user_id=v_uid and status='pending';
 if not found then raise exception 'KAISA_NO_PENDING_REQUEST'; end if;
end;
$$;

create or replace function public.kaisa_request_organization(
 p_name text,p_category text,p_description text,p_mission text,p_representative_name text,p_reason text)
returns uuid language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=auth.uid(); v_id uuid;
begin
 if v_uid is null then raise exception 'KAISA_LOGIN_REQUIRED'; end if;
 if not public.kaisa_is_tier2(v_uid) then raise exception 'KAISA_TIER2_REQUIRED'; end if;
 if char_length(btrim(coalesce(p_name,''))) not between 3 and 150
    or char_length(btrim(coalesce(p_description,''))) not between 20 and 300
    or char_length(btrim(coalesce(p_mission,''))) not between 5 and 300
    or char_length(btrim(coalesce(p_representative_name,''))) not between 3 and 150
    or char_length(btrim(coalesce(p_reason,''))) not between 30 and 500
    or char_length(btrim(coalesce(p_category,''))) not between 2 and 80
 then raise exception 'KAISA_INVALID_PROPOSAL'; end if;
 if exists(select 1 from public.kaisa_organization_proposals
    where requester_id=v_uid and lower(name)=lower(btrim(p_name)) and status='pending')
 then raise exception 'KAISA_DUPLICATE_PROPOSAL'; end if;
 insert into public.kaisa_organization_proposals(requester_id,name,category,description,mission,representative_name,reason)
 values(v_uid,btrim(p_name),btrim(p_category),btrim(p_description),btrim(p_mission),btrim(p_representative_name),btrim(p_reason))
 returning id into v_id;
 return v_id;
end;
$$;

revoke all on function public.kaisa_organizations_catalog(),public.kaisa_join_organization(uuid),
 public.kaisa_withdraw_organization(uuid),public.kaisa_request_organization(text,text,text,text,text,text) from public;
grant execute on function public.kaisa_organizations_catalog(),public.kaisa_join_organization(uuid),
 public.kaisa_withdraw_organization(uuid),public.kaisa_request_organization(text,text,text,text,text,text) to authenticated;

-- TEST DATA: Replace example name with actual LGU-approved org before production.
-- insert into public.kaisa_organizations(name,category,description,mission,location,status)
-- values('KAISA QA Volunteer Group','Community','Internal test organization for membership workflow.',
-- 'Verify organizational membership flows.','Test environment','published');
-- MANUAL LGU QA APPROVAL (only SQL Editor / trusted server; use exact IDs):
-- update public.kaisa_organization_memberships set status='approved', reviewed_at=now(), reviewed_by='<authorized-admin-uuid>'::uuid
-- where organization_id='<organization-uuid>'::uuid and user_id='<test-resident-uuid>'::uuid and status='pending';
-- Never grant database UPDATE access to residents to perform approvals.
