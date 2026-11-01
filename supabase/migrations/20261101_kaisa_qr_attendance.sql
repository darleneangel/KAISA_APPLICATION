-- KAISA QR Attendance MVP. Apply AFTER Events, Organizations and Tier 2 migrations.
-- Run as Supabase SQL editor/project owner. Event assignment is intentionally admin-only.
create extension if not exists pgcrypto;

create table if not exists public.kaisa_resident_qr_credentials (
 user_id uuid primary key references auth.users(id) on delete cascade,
 token_hash text unique,
 expires_at timestamptz,
 issued_at timestamptz,
 updated_at timestamptz not null default now()
);
create index if not exists kaisa_qr_token_lookup on public.kaisa_resident_qr_credentials(token_hash) where token_hash is not null;

create table if not exists public.kaisa_event_checkin_sessions (
 id uuid primary key default gen_random_uuid(),
 event_id uuid not null unique references public.kaisa_events(id) on delete cascade,
 organization_id uuid not null references public.kaisa_organizations(id),
 opens_at timestamptz not null,
 closes_at timestamptz not null,
 active boolean not null default true,
 created_at timestamptz not null default now(),
 constraint kaisa_attendance_session_time check (closes_at > opens_at)
);

create table if not exists public.kaisa_event_attendance (
 id uuid primary key default gen_random_uuid(),
 event_id uuid not null references public.kaisa_events(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 checked_in_at timestamptz not null,
 checked_out_at timestamptz,
 checked_in_by uuid not null references auth.users(id),
 checked_out_by uuid references auth.users(id),
 created_at timestamptz not null default now(),
 unique(event_id,user_id),
 constraint kaisa_check_out_after_in check (checked_out_at is null or checked_out_at >= checked_in_at)
);
create index if not exists kaisa_attendance_user_index on public.kaisa_event_attendance(user_id,checked_in_at desc);

create table if not exists public.kaisa_attendance_audit_logs (
 id bigint generated always as identity primary key,
 event_id uuid not null references public.kaisa_events(id) on delete cascade,
 resident_id uuid not null references auth.users(id),
 actor_id uuid not null references auth.users(id),
 action text not null check (action in ('check_in','check_out')),
 created_at timestamptz not null default now()
);

alter table public.kaisa_resident_qr_credentials enable row level security;
alter table public.kaisa_event_checkin_sessions enable row level security;
alter table public.kaisa_event_attendance enable row level security;
alter table public.kaisa_attendance_audit_logs enable row level security;
revoke all on public.kaisa_resident_qr_credentials, public.kaisa_event_checkin_sessions,
 public.kaisa_event_attendance, public.kaisa_attendance_audit_logs from anon,authenticated;
grant select on public.kaisa_event_attendance to authenticated;
drop policy if exists kaisa_attendance_read_own on public.kaisa_event_attendance;
create policy kaisa_attendance_read_own on public.kaisa_event_attendance for select to authenticated
 using (user_id = (select auth.uid()));
-- No direct resident/client access to QR tokens, session assignments or audit logs.

-- Returns a single fresh bearer token. Only authenticated Tier 2 user can issue their own QR.
create or replace function public.kaisa_issue_attendance_qr()
returns jsonb language plpgsql volatile security definer set search_path = '' as $$
declare
 v_uid uuid := auth.uid();
 v_token text;
 v_expires timestamptz := now() + interval '60 seconds';
begin
 if v_uid is null then raise exception 'KAISA_LOGIN_REQUIRED'; end if;
 if not public.kaisa_is_tier2(v_uid) then raise exception 'KAISA_TIER2_REQUIRED'; end if;
 v_token := 'KAISA1:' || replace(gen_random_uuid()::text,'-','') || replace(gen_random_uuid()::text,'-','');
 insert into public.kaisa_resident_qr_credentials(user_id,token_hash,expires_at,issued_at,updated_at)
 values(v_uid,encode(sha256(convert_to(v_token,'UTF8')),'hex'),v_expires,now(),now())
 on conflict(user_id) do update
 set token_hash=excluded.token_hash,expires_at=excluded.expires_at,
 issued_at=excluded.issued_at,updated_at=now();
 return jsonb_build_object('token',v_token,'expires_at',v_expires);
end;
$$;

-- Authorized scanners: approved organization Admin/Officer assigned to the event,
-- or Super Admin. Assignments are managed exclusively through privileged SQL/service-role.
create or replace function public.kaisa_can_scan_event(p_event_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
 select auth.uid() is not null and exists (
  select 1 from public.kaisa_event_checkin_sessions s
  where s.event_id=p_event_id and s.active
   and (
    exists (select 1 from public.kaisa_entitlements en
            where en.user_id=auth.uid() and en.is_super_admin=true)
    or exists (select 1 from public.kaisa_organization_memberships m
             where m.organization_id=s.organization_id and m.user_id=auth.uid()
              and m.status='approved' and m.role in ('Admin','Officer'))
   )
 );
$$;

create or replace function public.kaisa_scanner_events()
returns jsonb language sql stable security definer set search_path = '' as $$
 select coalesce(jsonb_agg(jsonb_build_object(
  'event_id',e.id,'title',e.title,'starts_at',e.starts_at,
  'opens_at',s.opens_at,'closes_at',s.closes_at
 ) order by e.starts_at),'[]'::jsonb)
 from public.kaisa_event_checkin_sessions s
 join public.kaisa_events e on e.id=s.event_id
 where s.active and e.status='published' and public.kaisa_can_scan_event(s.event_id);
$$;

-- Uses event choice from authorized scanner, not QR contents. Token is 60s + one-time.
create or replace function public.kaisa_scan_attendance(p_event_id uuid,p_token text,p_action text)
returns jsonb language plpgsql volatile security definer set search_path = '' as $$
declare
 v_admin uuid := auth.uid();
 v_resident uuid;
 v_session public.kaisa_event_checkin_sessions%rowtype;
 v_prev public.kaisa_event_attendance%rowtype;
 v_name text;
begin
 if v_admin is null then raise exception 'KAISA_LOGIN_REQUIRED'; end if;
 if p_action not in ('check_in','check_out') then raise exception 'KAISA_INVALID_ACTION'; end if;
 if p_token is null or p_token !~ '^KAISA1:[0-9a-f]{64}$' then raise exception 'KAISA_INVALID_QR'; end if;
 if not public.kaisa_can_scan_event(p_event_id) then raise exception 'KAISA_SCANNER_NOT_AUTHORIZED'; end if;
 select * into v_session from public.kaisa_event_checkin_sessions
  where event_id=p_event_id and active=true;
 if not found or now() < v_session.opens_at or now() > v_session.closes_at
 then raise exception 'KAISA_CHECKIN_WINDOW_CLOSED'; end if;
 -- Lock the token row: simultaneous scans cannot consume it more than once.
 select user_id into v_resident from public.kaisa_resident_qr_credentials
  where token_hash=encode(sha256(convert_to(p_token,'UTF8')),'hex')
    and expires_at>now() for update;
 if v_resident is null then raise exception 'KAISA_QR_EXPIRED_OR_USED'; end if;
 if not public.kaisa_is_tier2(v_resident) then raise exception 'KAISA_TIER2_REQUIRED'; end if;
 if not exists (
  select 1 from public.kaisa_event_registrations r
   where r.event_id=p_event_id and r.user_id=v_resident
    and r.status in ('registered','attended')
 ) then raise exception 'KAISA_PRE_REGISTRATION_REQUIRED'; end if;
 select * into v_prev from public.kaisa_event_attendance
  where event_id=p_event_id and user_id=v_resident for update;
 if p_action='check_in' then
  if v_prev.id is not null then raise exception 'KAISA_ALREADY_CHECKED_IN'; end if;
  insert into public.kaisa_event_attendance(event_id,user_id,checked_in_at,checked_in_by)
   values(p_event_id,v_resident,now(),v_admin);
 else
  if v_prev.id is null then raise exception 'KAISA_CHECKIN_REQUIRED_FIRST'; end if;
  if v_prev.checked_out_at is not null then raise exception 'KAISA_ALREADY_CHECKED_OUT'; end if;
  update public.kaisa_event_attendance set checked_out_at=now(),checked_out_by=v_admin
   where id=v_prev.id;
  -- Check-out marks the existing registration as attended.
  update public.kaisa_event_registrations set status='attended'
   where event_id=p_event_id and user_id=v_resident and status='registered';
 end if;
 insert into public.kaisa_attendance_audit_logs(event_id,resident_id,actor_id,action)
  values(p_event_id,v_resident,v_admin,p_action);
 update public.kaisa_resident_qr_credentials set token_hash=null,expires_at=null,
  updated_at=now() where user_id=v_resident;
 -- Only return public display name to authorized scanner. No address, birthday or ID details.
 select concat_ws(' ',r.first_name,r.last_name) into v_name
  from public.resident_profiles r where r.user_id=v_resident;
 return jsonb_build_object('success',true,'action',p_action,
  'resident_name',coalesce(nullif(btrim(v_name),''),'KAISA Resident'),
  'timestamp',now());
end;
$$;

revoke all on function public.kaisa_issue_attendance_qr(),
 public.kaisa_can_scan_event(uuid),public.kaisa_scanner_events(),
 public.kaisa_scan_attendance(uuid,text,text) from public,anon;
grant execute on function public.kaisa_issue_attendance_qr(),
 public.kaisa_can_scan_event(uuid),public.kaisa_scanner_events(),
 public.kaisa_scan_attendance(uuid,text,text) to authenticated;

-- ADMINISTRATIVE SETUP (SQL Editor / service-role only):
-- Connect an existing published event to an existing approved organization:
-- insert into public.kaisa_event_checkin_sessions(event_id, organization_id, opens_at, closes_at)
-- values ('EVENT_UUID','ORGANIZATION_UUID','2026-11-15 07:00:00+08','2026-11-15 13:00:00+08');
-- The scanner must be an APPROVED Admin/Officer of that organization (or Super Admin).
-- IMPORTANT: This MVP does not issue certificates automatically and cannot prove physical presence by itself.
