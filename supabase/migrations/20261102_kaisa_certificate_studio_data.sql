-- KAISA E-Certificate Studio: read-only, organization-scoped event + verified attendance RPCs.
-- Prerequisites: Events V1, QR Attendance V1, Organization Admin V1, Tier 2 function.
-- Event ownership is determined by kaisa_event_checkin_sessions.organization_id,
-- NOT the untrusted human-readable kaisa_events.organization_name.
-- Apply in Supabase SQL Editor after backing up; test as an authenticated Org Admin.

create or replace function public.kaisa_certificate_events(p_organization_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  if auth.uid() is null or not public.kaisa_admin_is_allowed(p_organization_id) then
    raise exception 'KAISA_CERTIFICATE_ADMIN_REQUIRED';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id',e.id,'title',e.title,'starts_at',e.starts_at,
      'location',e.location,'organization_id',s.organization_id
    ) order by e.starts_at desc)
    from public.kaisa_event_checkin_sessions s
    join public.kaisa_events e on e.id=s.event_id
    where s.organization_id=p_organization_id and e.status='published'
  ),'[]'::jsonb);
end;
$$;

create or replace function public.kaisa_certificate_attendees(
  p_organization_id uuid, p_event_id uuid
)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  if auth.uid() is null or not public.kaisa_admin_is_allowed(p_organization_id) then
    raise exception 'KAISA_CERTIFICATE_ADMIN_REQUIRED';
  end if;
  if not exists (
    select 1 from public.kaisa_event_checkin_sessions s
    join public.kaisa_events e on e.id=s.event_id
    where s.organization_id=p_organization_id and s.event_id=p_event_id
      and e.status='published'
  ) then
    raise exception 'KAISA_CERTIFICATE_EVENT_NOT_OWNED';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'user_id',a.user_id,
      'name',btrim(concat_ws(' ',p.first_name,p.last_name)),
      'checked_in_at',a.checked_in_at,
      'checked_out_at',a.checked_out_at
    ) order by p.last_name,p.first_name,a.user_id)
    from public.kaisa_event_attendance a
    join public.kaisa_event_registrations r
      on r.event_id=a.event_id and r.user_id=a.user_id
    join public.resident_profiles p on p.user_id=a.user_id
    where a.event_id=p_event_id
      and a.checked_in_at is not null
      and r.status in ('registered','attended')
      and public.kaisa_is_tier2(a.user_id)
      and length(btrim(concat_ws(' ',p.first_name,p.last_name))) > 0
  ),'[]'::jsonb);
end;
$$;

revoke all on function public.kaisa_certificate_events(uuid),
  public.kaisa_certificate_attendees(uuid,uuid) from public,anon;
grant execute on function public.kaisa_certificate_events(uuid),
  public.kaisa_certificate_attendees(uuid,uuid) to authenticated;
