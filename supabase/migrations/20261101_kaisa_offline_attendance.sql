-- APPLY AFTER 20261101_kaisa_qr_attendance.sql. Review/test in staging.
-- Offline pass is EVENT-SPECIFIC and pre-provisioned online; unlike online rotating
-- QR it remains stable until the event closes. QR contains no PII.
create extension if not exists pgcrypto;
create table if not exists public.kaisa_offline_event_passes (
 id uuid primary key default gen_random_uuid(),
 event_id uuid not null references public.kaisa_events(id) on delete cascade,
 resident_id uuid not null references auth.users(id) on delete cascade,
 token_hash text not null unique,
 expires_at timestamptz not null,
 revoked_at timestamptz,
 created_at timestamptz not null default now(),
 unique (event_id,resident_id)
);
create table if not exists public.kaisa_offline_sync_operations (
 operation_id uuid primary key,
 event_id uuid not null references public.kaisa_events(id),
 resident_id uuid not null references auth.users(id),
 scanner_id uuid not null references auth.users(id),
 action text not null check(action in ('check_in','check_out')),
 claimed_scanned_at timestamptz not null,
 received_at timestamptz not null default now(),
 result jsonb not null
);
alter table public.kaisa_offline_event_passes enable row level security;
alter table public.kaisa_offline_sync_operations enable row level security;
revoke all on public.kaisa_offline_event_passes,public.kaisa_offline_sync_operations from anon, authenticated;
-- Issue/reissue a pass for the CURRENT RESIDENT and a pre-registered event.
create or replace function public.kaisa_issue_offline_event_pass(p_event_id uuid)
returns jsonb language plpgsql volatile security definer set search_path='' as $$
declare v_uid uuid:=auth.uid(); v_end timestamptz; v_token text; v_hash text;
begin
 if v_uid is null then raise exception 'KAISA_LOGIN_REQUIRED'; end if;
 if not public.kaisa_is_tier2(v_uid) then raise exception 'KAISA_TIER2_REQUIRED'; end if;
 select least(s.closes_at+interval '10 minutes',e.ends_at+interval '8 hours') into v_end
 from public.kaisa_event_checkin_sessions s join public.kaisa_events e on e.id=s.event_id
 where e.id=p_event_id and e.status='published' and s.active and s.closes_at>now();
 if v_end is null then raise exception 'KAISA_NO_ACTIVE_EVENT_SESSION'; end if;
 if not exists(select 1 from public.kaisa_event_registrations r where r.event_id=p_event_id and r.user_id=v_uid and r.status='registered')
 then raise exception 'KAISA_PRE_REGISTRATION_REQUIRED'; end if;
 v_token:='KAISAOFF2:'||encode(gen_random_bytes(32),'hex');
 v_hash:=encode(digest(v_token,'sha256'),'hex');
 insert into public.kaisa_offline_event_passes(event_id,resident_id,token_hash,expires_at)
 values(p_event_id,v_uid,v_hash,v_end)
 on conflict(event_id,resident_id) do update set token_hash=excluded.token_hash, expires_at=excluded.expires_at,revoked_at=null;
 return jsonb_build_object('event_id',p_event_id,'token',v_token,'expires_at',v_end);
end $$;
-- Offline roster contains ONLY token hashes, NOT names or other private details.
-- Staff permission is revalidated each time roster is downloaded.
create or replace function public.kaisa_offline_roster(p_event_id uuid)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare v_items jsonb; v_session public.kaisa_event_checkin_sessions%rowtype;
begin
 if auth.uid() is null or not public.kaisa_can_scan_event(p_event_id) then raise exception 'KAISA_SCANNER_NOT_AUTHORIZED'; end if;
 select * into v_session from public.kaisa_event_checkin_sessions where event_id=p_event_id and active;
 if not found or v_session.closes_at<now() then raise exception 'KAISA_SESSION_UNAVAILABLE'; end if;
 select coalesce(jsonb_agg(jsonb_build_object('hash',p.token_hash,'expires_at',p.expires_at)),'[]'::jsonb)
 into v_items from public.kaisa_offline_event_passes p
 join public.kaisa_event_registrations r on r.event_id=p.event_id and r.user_id=p.resident_id
 where p.event_id=p_event_id and p.revoked_at is null and p.expires_at>now() and r.status in ('registered','attended');
 return jsonb_build_object('event_id',p_event_id,'opens_at',v_session.opens_at,'closes_at',v_session.closes_at,
  'fetched_at',now(),'entries',v_items);
end $$;
-- Synchronization is idempotent by operation_id. Scanned-at is client claimed,
-- NOT trusted as server time. All late/offline results remain PROVISIONAL until review.
create or replace function public.kaisa_sync_offline_scan(
 p_operation_id uuid,p_event_id uuid,p_token text,p_action text,p_scanned_at timestamptz)
returns jsonb language plpgsql volatile security definer set search_path='' as $$
declare v_uid uuid:=auth.uid();v_resident uuid; v_session public.kaisa_event_checkin_sessions%rowtype;
 v_prev public.kaisa_event_attendance%rowtype; v_result jsonb;v_existing public.kaisa_offline_sync_operations%rowtype;
begin
 if v_uid is null or not public.kaisa_can_scan_event(p_event_id) then raise exception 'KAISA_SCANNER_NOT_AUTHORIZED'; end if;
 if p_action not in ('check_in','check_out') or p_token is null or p_token !~ '^KAISAOFF2:[0-9a-f]{64}$' then raise exception 'KAISA_INVALID_SCAN';end if;
 perform pg_advisory_xact_lock(hashtextextended(p_operation_id::text,0));
 select * into v_existing from public.kaisa_offline_sync_operations where operation_id=p_operation_id;
 if found then
  if v_existing.scanner_id<>v_uid or v_existing.event_id<>p_event_id or v_existing.action<>p_action then raise exception 'KAISA_OPERATION_ID_CONFLICT'; end if;
  return v_existing.result;
 end if;
 select * into v_session from public.kaisa_event_checkin_sessions where event_id=p_event_id and active;
 if not found then raise exception 'KAISA_EVENT_SESSION_UNAVAILABLE';end if;
 if p_scanned_at < v_session.opens_at or p_scanned_at>v_session.closes_at
    or p_scanned_at>now()+interval '5 minutes' or p_scanned_at<now()-interval '72 hours'
 then raise exception 'KAISA_SCAN_TIME_REVIEW_REQUIRED'; end if;
 select resident_id into v_resident from public.kaisa_offline_event_passes
 where event_id=p_event_id and token_hash=encode(digest(p_token,'sha256'),'hex')
   and revoked_at is null and expires_at>=p_scanned_at;
 if v_resident is null then raise exception 'KAISA_UNKNOWN_OR_REVOKED_PASS';end if;
 if not public.kaisa_is_tier2(v_resident) then raise exception 'KAISA_TIER2_REQUIRED';end if;
 if not exists(select 1 from public.kaisa_event_registrations where event_id=p_event_id and user_id=v_resident and status in ('registered','attended'))
 then raise exception 'KAISA_PRE_REGISTRATION_REQUIRED';end if;
 -- Serialize check-in/check-out for the event and resident across scanner devices.
 perform pg_advisory_xact_lock(hashtextextended(p_event_id::text||v_resident::text,0));
 select * into v_prev from public.kaisa_event_attendance where event_id=p_event_id and user_id=v_resident for update;
 if p_action='check_in' then
  if v_prev.id is not null then raise exception 'KAISA_ALREADY_CHECKED_IN'; end if;
  insert into public.kaisa_event_attendance(event_id,user_id,checked_in_at,checked_in_by)
  values(p_event_id,v_resident,p_scanned_at,v_uid);
 else
  if v_prev.id is null then raise exception 'KAISA_CHECKIN_REQUIRED_FIRST';end if;
  if v_prev.checked_out_at is not null then raise exception 'KAISA_ALREADY_CHECKED_OUT';end if;
  if p_scanned_at<v_prev.checked_in_at then raise exception 'KAISA_CHECKOUT_BEFORE_CHECKIN';end if;
  update public.kaisa_event_attendance set checked_out_at=p_scanned_at,checked_out_by=v_uid where id=v_prev.id;
  update public.kaisa_event_registrations set status='attended' where event_id=p_event_id and user_id=v_resident and status='registered';
 end if;
 insert into public.kaisa_attendance_audit_logs(event_id,resident_id,actor_id,action)
 values(p_event_id,v_resident,v_uid,p_action);
 v_result:=jsonb_build_object('success',true,'status','synced','action',p_action,'event_id',p_event_id);
 insert into public.kaisa_offline_sync_operations(operation_id,event_id,resident_id,scanner_id,action,claimed_scanned_at,result)
 values(p_operation_id,p_event_id,v_resident,v_uid,p_action,p_scanned_at,v_result);
 return v_result;
end $$;
revoke all on function public.kaisa_issue_offline_event_pass(uuid),public.kaisa_offline_roster(uuid),
 public.kaisa_sync_offline_scan(uuid,uuid,text,text,timestamptz) from public,anon;
grant execute on function public.kaisa_issue_offline_event_pass(uuid),public.kaisa_offline_roster(uuid),
 public.kaisa_sync_offline_scan(uuid,uuid,text,text,timestamptz) to authenticated;
