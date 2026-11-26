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
  -- The organizer records extra document checks in the event briefing.
  if v_event.instructions ~* '(?n)^Registration requirements:[[:blank:]]*[^[:space:]]' then
    raise exception 'KAISA_ORGANIZER_APPROVAL_REQUIRED';
  end if;
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
