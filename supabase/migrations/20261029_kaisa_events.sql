-- KAISA Events MVP -- apply after the Community Feed/Tier 2 migration.
-- Does not create mock organizations or change existing authorization.
-- Events must be published by authorized LGU administration through SQL/service-role.

create table if not exists public.kaisa_events (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(btrim(title)) between 3 and 150),
  organization_name text not null check (char_length(btrim(organization_name)) between 2 and 150),
  category text not null default 'Community',
  description text not null default '',
  location text not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  capacity integer not null check (capacity between 1 and 100000),
  status text not null default 'draft' check (status in ('draft','published','cancelled')),
  created_at timestamptz not null default now(),
  constraint kaisa_events_valid_time check (ends_at > starts_at)
);
create index if not exists kaisa_events_published_idx on public.kaisa_events(starts_at) where status='published';

create table if not exists public.kaisa_event_registrations (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.kaisa_events(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'registered' check (status in ('registered','cancelled','attended')),
  registered_at timestamptz not null default now(),
  cancelled_at timestamptz,
  unique(event_id, user_id)
);
create index if not exists kaisa_event_registrations_user_idx on public.kaisa_event_registrations(user_id, status);

alter table public.kaisa_events enable row level security;
alter table public.kaisa_event_registrations enable row level security;
revoke all on public.kaisa_events, public.kaisa_event_registrations from anon, authenticated;
grant select on public.kaisa_events, public.kaisa_event_registrations to authenticated;

-- Public event details only for published events; draft/cancelled remain invisible.
drop policy if exists kaisa_events_read_published on public.kaisa_events;
create policy kaisa_events_read_published on public.kaisa_events for select to authenticated
using (status='published');
drop policy if exists kaisa_event_registrations_read_own on public.kaisa_event_registrations;
create policy kaisa_event_registrations_read_own on public.kaisa_event_registrations for select to authenticated
using (user_id = (select auth.uid()));
-- Intentionally NO direct insert/update/delete policies for authenticated users.
-- SECURITY DEFINER RPCs perform atomic operations; client cannot fake status or bypass capacity.

create or replace function public.kaisa_events_catalog()
returns jsonb language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', e.id, 'title', e.title, 'organization_name', e.organization_name,
    'category', e.category, 'description', e.description, 'location', e.location,
    'starts_at', e.starts_at, 'ends_at', e.ends_at, 'capacity', e.capacity,
    'registered_count', (select count(*) from public.kaisa_event_registrations r
      where r.event_id=e.id and r.status in ('registered','attended')),
    'my_status', (select r.status from public.kaisa_event_registrations r
      where r.event_id=e.id and r.user_id=(select auth.uid()))
  ) order by e.starts_at), '[]'::jsonb)
  from public.kaisa_events e where e.status='published';
$$;

create or replace function public.kaisa_register_event(p_event_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := auth.uid();
  v_event public.kaisa_events%rowtype;
  v_count integer;
  v_current text;
begin
  if v_user is null then raise exception 'KAISA_LOGIN_REQUIRED'; end if;
  -- Entitlements are server-maintained; never trust resident_tier in auth metadata.
  if not public.kaisa_is_tier2(v_user) then raise exception 'KAISA_TIER2_REQUIRED'; end if;
  -- Locks the event row so concurrent registrations cannot overbook capacity.
  select * into v_event from public.kaisa_events where id=p_event_id for update;
  if not found or v_event.status <> 'published' then raise exception 'KAISA_EVENT_UNAVAILABLE'; end if;
  if v_event.starts_at <= now() then raise exception 'KAISA_REGISTRATION_CLOSED'; end if;
  select status into v_current from public.kaisa_event_registrations
    where event_id=p_event_id and user_id=v_user;
  if v_current in ('registered','attended') then raise exception 'KAISA_ALREADY_REGISTERED'; end if;
  select count(*) into v_count from public.kaisa_event_registrations
    where event_id=p_event_id and status in ('registered','attended');
  if v_count >= v_event.capacity then raise exception 'KAISA_EVENT_FULL'; end if;
  insert into public.kaisa_event_registrations(event_id,user_id,status,registered_at,cancelled_at)
  values(p_event_id,v_user,'registered',now(),null)
  on conflict(event_id,user_id) do update
    set status='registered', registered_at=now(), cancelled_at=null;
end;
$$;

create or replace function public.kaisa_cancel_event_registration(p_event_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := auth.uid();
  v_start timestamptz;
  v_status text;
begin
  if v_user is null then raise exception 'KAISA_LOGIN_REQUIRED'; end if;
  select starts_at into v_start from public.kaisa_events where id=p_event_id for update;
  if not found then raise exception 'KAISA_EVENT_UNAVAILABLE'; end if;
  if v_start <= now() then raise exception 'KAISA_CANCELLATION_CLOSED'; end if;
  select status into v_status from public.kaisa_event_registrations
    where event_id=p_event_id and user_id=v_user;
  if v_status is distinct from 'registered' then raise exception 'KAISA_NO_ACTIVE_REGISTRATION'; end if;
  update public.kaisa_event_registrations set status='cancelled',cancelled_at=now()
  where event_id=p_event_id and user_id=v_user and status='registered';
end;
$$;

revoke all on function public.kaisa_events_catalog(),
  public.kaisa_register_event(uuid),public.kaisa_cancel_event_registration(uuid) from public;
grant execute on function public.kaisa_events_catalog(),
  public.kaisa_register_event(uuid),public.kaisa_cancel_event_registration(uuid) to authenticated;

-- Test event (optional): create from Supabase SQL Editor once the LGU approves the content.
-- Dates below are EXAMPLES; replace before publishing.
-- insert into public.kaisa_events(title, organization_name,category,description,location,starts_at,ends_at,capacity,status)
-- values('Community Clean-Up Drive','LGU / Approved Organizer','Environment',
--        'Join our community activity.','Approved venue',
--        '2026-11-15 08:00:00+08','2026-11-15 11:00:00+08',80,'published');
