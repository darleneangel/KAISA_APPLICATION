-- KAISA Organization Announcements MVP
-- Prerequisites: kaisa_organizations, memberships, entitlements, kaisa_notifications.
-- Public means readable by signed-in KAISA accounts; it does not mean anonymous internet access.
-- For this MVP notifications target approved organization members (not all KAISA residents).
create extension if not exists pgcrypto;

create table if not exists public.kaisa_org_announcements (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.kaisa_organizations(id) on delete cascade,
  author_id uuid not null references auth.users(id),
  title text not null check (char_length(btrim(title)) between 1 and 120),
  body text not null check (char_length(btrim(body)) between 1 and 4000),
  visibility text not null check (visibility in ('public','members')),
  notify_in_app boolean not null default false,
  notify_email boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists kaisa_org_announcements_org_recent_idx
  on public.kaisa_org_announcements(organization_id,created_at desc);

-- Email jobs are a service-role-only queue; a trusted Edge Function/worker
-- needs to process queued items and honor recipient email preferences.
create table if not exists public.kaisa_org_announcement_email_jobs (
  id uuid primary key default gen_random_uuid(),
  announcement_id uuid not null references public.kaisa_org_announcements(id) on delete cascade,
  recipient_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','sent','failed','skipped')),
  attempts int not null default 0,
  last_error text,
  created_at timestamptz not null default now(),
  sent_at timestamptz,
  unique(announcement_id,recipient_id)
);
create index if not exists kaisa_org_announcement_email_pending_idx
  on public.kaisa_org_announcement_email_jobs(status,created_at) where status='pending';

alter table public.kaisa_org_announcements enable row level security;
alter table public.kaisa_org_announcement_email_jobs enable row level security;
revoke all on public.kaisa_org_announcements from anon,authenticated;
revoke all on public.kaisa_org_announcement_email_jobs from anon,authenticated;
-- Deliberately NO direct client access or RLS policy: use vetted RPCs only.

create or replace function public.kaisa_org_announcement_publish(
 p_organization_id uuid, p_title text, p_body text,
 p_visibility text, p_notify_in_app boolean default false, p_notify_email boolean default false)
returns uuid language plpgsql security definer set search_path='' as $$
declare v_id uuid; v_uid uuid := auth.uid(); v_title text := btrim(coalesce(p_title,''));
 v_body text := btrim(coalesce(p_body,''));
begin
 if v_uid is null then raise exception 'KAISA_LOGIN_REQUIRED'; end if;
 if not exists (
   select 1 from public.kaisa_organization_memberships m
   join public.kaisa_organizations o on o.id=m.organization_id
   where m.organization_id=p_organization_id and m.user_id=v_uid
     and m.status='approved' and m.role='Admin' and o.status='published'
 ) then raise exception 'KAISA_ORG_ADMIN_REQUIRED'; end if;
 if char_length(v_title) not between 1 and 120 then raise exception 'KAISA_TITLE_LENGTH'; end if;
 if char_length(v_body) not between 1 and 4000 then raise exception 'KAISA_BODY_LENGTH'; end if;
 if p_visibility is null or p_visibility not in ('public','members') then
   raise exception 'KAISA_INVALID_VISIBILITY'; end if;
 insert into public.kaisa_org_announcements(organization_id,author_id,title,body,visibility,notify_in_app,notify_email)
 values(p_organization_id,v_uid,v_title,v_body,p_visibility,coalesce(p_notify_in_app,false),coalesce(p_notify_email,false))
 returning id into v_id;

 if coalesce(p_notify_in_app,false) then
   insert into public.kaisa_notifications(recipient_id,actor_id,kind,title,body,target_path,dedupe_key)
   select distinct m.user_id,v_uid,'organization',left(v_title,120),left(v_body,500),
     '/resident/organizations','org-announcement:'||v_id::text||':'||m.user_id::text
   from public.kaisa_organization_memberships m
   where m.organization_id=p_organization_id and m.status='approved' and m.user_id<>v_uid
   on conflict(dedupe_key) do nothing;
 end if;
 if coalesce(p_notify_email,false) then
   insert into public.kaisa_org_announcement_email_jobs(announcement_id,recipient_id)
   select v_id,m.user_id from public.kaisa_organization_memberships m
   where m.organization_id=p_organization_id and m.status='approved' and m.user_id<>v_uid
   on conflict(announcement_id,recipient_id) do nothing;
 end if;
 return v_id;
end $$;

-- Returns only public announcements or announcements of an approved membership.
-- Admin/Officer isn't implicitly enough unless membership is approved.
create or replace function public.kaisa_org_announcements_list(
 p_organization_id uuid, p_limit integer default 30)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare v_out jsonb;
begin
 if auth.uid() is null then raise exception 'KAISA_LOGIN_REQUIRED'; end if;
 if not exists(select 1 from public.kaisa_organizations o
    where o.id=p_organization_id and o.status='published') then
   raise exception 'KAISA_ORGANIZATION_UNAVAILABLE'; end if;
 select coalesce(jsonb_agg(to_jsonb(t) order by t.created_at desc),'[]'::jsonb) into v_out
 from (
   select a.id,a.organization_id,a.title,a.body,a.visibility,a.created_at,
          a.notify_in_app,a.notify_email
   from public.kaisa_org_announcements a
   where a.organization_id=p_organization_id and (
     a.visibility='public' or exists (
       select 1 from public.kaisa_organization_memberships m
       where m.organization_id=a.organization_id and m.user_id=auth.uid() and m.status='approved'
     ))
   order by a.created_at desc limit least(greatest(coalesce(p_limit,30),1),100)
 ) t;
 return v_out;
end $$;

revoke all on function public.kaisa_org_announcement_publish(uuid,text,text,text,boolean,boolean) from public;
revoke all on function public.kaisa_org_announcements_list(uuid,integer) from public;
grant execute on function public.kaisa_org_announcement_publish(uuid,text,text,text,boolean,boolean) to authenticated;
grant execute on function public.kaisa_org_announcements_list(uuid,integer) to authenticated;
