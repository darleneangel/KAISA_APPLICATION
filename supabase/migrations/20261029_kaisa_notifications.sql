-- KAISA notifications v1. Run after Feed, Messaging, Events, Organizations, and Profile migrations.
create extension if not exists pgcrypto;
create table if not exists public.kaisa_notifications (
 id uuid primary key default gen_random_uuid(),
 recipient_id uuid not null references auth.users(id) on delete cascade,
 actor_id uuid references auth.users(id) on delete set null,
 kind text not null check(kind in ('message','like','comment','post','event','organization','verification','certificate','system')),
 title text not null check(char_length(title) between 1 and 120),
 body text not null default '' check(char_length(body) <= 500),
 target_path text not null default '/resident/home' check (left(target_path,10)='/resident/'),
 is_read boolean not null default false,
 created_at timestamptz not null default now(),
 dedupe_key text unique
);
create index if not exists kaisa_notification_inbox_idx on public.kaisa_notifications(recipient_id,created_at desc);
create index if not exists kaisa_notification_unread_idx on public.kaisa_notifications(recipient_id,created_at desc) where is_read=false;
alter table public.kaisa_notifications enable row level security;
revoke all on public.kaisa_notifications from anon, authenticated;
grant select on public.kaisa_notifications to authenticated;
drop policy if exists kaisa_notification_select_self on public.kaisa_notifications;
create policy kaisa_notification_select_self on public.kaisa_notifications for select to authenticated using (recipient_id=(select auth.uid()));
-- Client can only change read-state through authenticated RPCs. No client INSERT/DELETE.
create or replace function public.kaisa_notification_mark_read(p_id uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'Not authenticated'; end if;
 update public.kaisa_notifications set is_read=true where id=p_id and recipient_id=auth.uid();
end $$;
create or replace function public.kaisa_notification_mark_all_read()
returns void language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'Not authenticated'; end if;
 update public.kaisa_notifications set is_read=true where recipient_id=auth.uid() and not is_read;
end $$;
revoke all on function public.kaisa_notification_mark_read(uuid) from public;
revoke all on function public.kaisa_notification_mark_all_read() from public;
grant execute on function public.kaisa_notification_mark_read(uuid) to authenticated;
grant execute on function public.kaisa_notification_mark_all_read() to authenticated;

-- All notification INSERTs happen inside trusted database triggers, not from the Flutter client.
create or replace function public.kaisa_notify_activity()
returns trigger language plpgsql security definer set search_path='' as $$
declare v_owner uuid; v_title text; v_path text; v_kind text; v_actor uuid; v_recipient uuid; v_body text:='';
begin
 if TG_TABLE_NAME='kaisa_direct_messages' and TG_OP='INSERT' then
   v_recipient:=new.recipient_id; v_actor:=new.sender_id; v_kind:='message';
   v_title:='New message'; v_body:=left(new.body,150); v_path:='/resident/messages/'||new.sender_id::text;
 elsif TG_TABLE_NAME='kaisa_feed_likes' and TG_OP='INSERT' then
   select author_id into v_recipient from public.kaisa_feed_posts where id=new.post_id;
   v_actor:=new.user_id; v_kind:='like'; v_title:='Someone liked your post'; v_path:='/resident/feed';
 elsif TG_TABLE_NAME='kaisa_feed_comments' and TG_OP='INSERT' then
   select author_id into v_recipient from public.kaisa_feed_posts where id=new.post_id;
   v_actor:=new.author_id; v_kind:='comment'; v_title:='New comment on your post'; v_path:='/resident/feed';
 elsif TG_TABLE_NAME='kaisa_event_registrations' and (TG_OP='INSERT' or (TG_OP='UPDATE' and old.status is distinct from new.status)) then
   v_recipient:=new.user_id; v_actor:=null; v_kind:='event';
   v_title:=case new.status when 'registered' then 'Event registration confirmed' when 'attended' then 'Attendance confirmed' else 'Event registration updated' end;
   v_path:='/resident/my-events';
 elsif TG_TABLE_NAME='kaisa_organization_memberships' and (TG_OP='INSERT' or (TG_OP='UPDATE' and old.status is distinct from new.status)) then
   v_recipient:=new.user_id; v_actor:=null; v_kind:='organization';
   v_title:=case new.status when 'pending' then 'Membership request submitted' when 'approved' then 'Membership approved' when 'rejected' then 'Membership request declined' else 'Membership request updated' end;
   v_path:='/resident/my-organizations';
 elsif TG_TABLE_NAME='kaisa_organization_proposals' and (TG_OP='INSERT' or (TG_OP='UPDATE' and old.status is distinct from new.status)) then
   v_recipient:=new.requester_id; v_actor:=null; v_kind:='organization';
   v_title:=case new.status when 'pending' then 'Organization proposal submitted' when 'approved' then 'Organization proposal approved' else 'Organization proposal updated' end;
   v_path:='/resident/organizations';
 elsif TG_TABLE_NAME='kaisa_identity_requests' and (TG_OP='INSERT' or (TG_OP='UPDATE' and old.status is distinct from new.status)) then
   v_recipient:=new.user_id; v_actor:=null; v_kind:='verification';
   v_title:=case new.status when 'pending' then 'Verification submitted' when 'approved' then 'Identity verification approved' else 'Verification status updated' end;
   v_path:='/resident/verification-status';
 else return new;
 end if;
 if v_recipient is not null and (v_actor is null or v_actor<>v_recipient) then
   insert into public.kaisa_notifications(recipient_id,actor_id,kind,title,body,target_path)
   values(v_recipient,v_actor,v_kind,v_title,v_body,v_path);
 end if;
 return new;
end $$;
-- Note: SQL CASE above only evaluates new.body for direct-message rows.
drop trigger if exists kaisa_notify_direct_message on public.kaisa_direct_messages;
create trigger kaisa_notify_direct_message after insert on public.kaisa_direct_messages for each row execute function public.kaisa_notify_activity();
drop trigger if exists kaisa_notify_like on public.kaisa_feed_likes;
create trigger kaisa_notify_like after insert on public.kaisa_feed_likes for each row execute function public.kaisa_notify_activity();
drop trigger if exists kaisa_notify_comment on public.kaisa_feed_comments;
create trigger kaisa_notify_comment after insert on public.kaisa_feed_comments for each row execute function public.kaisa_notify_activity();
drop trigger if exists kaisa_notify_event_registration on public.kaisa_event_registrations;
create trigger kaisa_notify_event_registration after insert or update of status on public.kaisa_event_registrations for each row execute function public.kaisa_notify_activity();
drop trigger if exists kaisa_notify_org_membership on public.kaisa_organization_memberships;
create trigger kaisa_notify_org_membership after insert or update of status on public.kaisa_organization_memberships for each row execute function public.kaisa_notify_activity();
drop trigger if exists kaisa_notify_org_proposal on public.kaisa_organization_proposals;
create trigger kaisa_notify_org_proposal after insert or update of status on public.kaisa_organization_proposals for each row execute function public.kaisa_notify_activity();
drop trigger if exists kaisa_notify_verification on public.kaisa_identity_requests;
create trigger kaisa_notify_verification after insert or update of status on public.kaisa_identity_requests for each row execute function public.kaisa_notify_activity();
-- Supabase Realtime: add notification table to publication (replica identity primary key is sufficient).
do $$ begin
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='kaisa_notifications') then
   alter publication supabase_realtime add table public.kaisa_notifications;
 end if;
end $$;

-- Certificate issuance notification (Profile MVP certificate table).
create or replace function public.kaisa_notify_certificate()
returns trigger language plpgsql security definer set search_path='' as $$
begin
 insert into public.kaisa_notifications(recipient_id,kind,title,body,target_path,dedupe_key)
 values(new.resident_id,'certificate','New e-certificate issued','Your new certificate is available in your profile.','/resident/profile','certificate:'||new.id::text)
 on conflict(dedupe_key) do nothing;
 return new;
end $$;
drop trigger if exists kaisa_notify_certificate_issued on public.kaisa_resident_certificates;
create trigger kaisa_notify_certificate_issued after insert on public.kaisa_resident_certificates
for each row execute function public.kaisa_notify_certificate();
