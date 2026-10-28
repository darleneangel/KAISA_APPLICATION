-- KAISA profile and messaging MVP. Apply after resident_profiles, feed, events, Tier 2 migrations.
-- DO NOT expose resident_profiles directly to other residents.
create extension if not exists pgcrypto;
alter table public.resident_profiles add column if not exists bio text;
alter table public.resident_profiles add column if not exists avatar_path text;

-- Profile image files are PUBLIC; users should never put documents/IDs in this bucket.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('kaisa-avatars','kaisa-avatars',true,2097152,array['image/jpeg','image/png','image/webp'])
on conflict(id) do update set public=true,file_size_limit=2097152,allowed_mime_types=excluded.allowed_mime_types;
drop policy if exists kaisa_avatar_read on storage.objects;
create policy kaisa_avatar_read on storage.objects for select to authenticated using(bucket_id='kaisa-avatars');
drop policy if exists kaisa_avatar_upload on storage.objects;
create policy kaisa_avatar_upload on storage.objects for insert to authenticated
with check (bucket_id='kaisa-avatars' and (storage.foldername(name))[1]=auth.uid()::text
 and lower(storage.extension(name)) in ('jpg','jpeg','png','webp'));
drop policy if exists kaisa_avatar_delete on storage.objects;
create policy kaisa_avatar_delete on storage.objects for delete to authenticated
using (bucket_id='kaisa-avatars' and (storage.foldername(name))[1]=auth.uid()::text);

-- Controlled edit: no client-authorized changes to Tier 2 / role / other personal fields.
create or replace function public.kaisa_set_public_profile(p_bio text, p_avatar_path text)
returns void language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'Not authenticated'; end if;
 if char_length(coalesce(p_bio,'')) > 300 then raise exception 'Bio is too long'; end if;
 if p_avatar_path is not null and p_avatar_path <> '' then
   if split_part(p_avatar_path,'/',1) <> auth.uid()::text then raise exception 'Invalid avatar path'; end if;
   if not exists(select 1 from storage.objects where bucket_id='kaisa-avatars' and name=p_avatar_path) then
     raise exception 'Avatar does not exist'; end if;
 end if;
 update public.resident_profiles
 set bio=nullif(btrim(p_bio),''), avatar_path=nullif(p_avatar_path,'')
 where user_id=auth.uid();
 if not found then raise exception 'Please complete resident profile setup first'; end if;
end $$;
-- In case an older schema requires other NOT NULL profile fields, initial profile setup must occur before editing bio.
revoke all on function public.kaisa_set_public_profile(text,text) from public;
grant execute on function public.kaisa_set_public_profile(text,text) to authenticated;

-- Only safe social fields are returned, NEVER street, contact, ID, DOB or email.
create or replace function public.kaisa_public_profile(p_user_id uuid) returns jsonb
language sql stable security definer set search_path='' as $$
 select case when auth.uid() is null then null else (
   select jsonb_build_object(
     'user_id',r.user_id,
     'display_name',coalesce(nullif(btrim(concat_ws(' ',r.first_name,r.last_name)),''),nullif(r.full_name,''),'KAISA Resident'),
     'bio',coalesce(r.bio,''),
     'avatar_path',r.avatar_path,
     'verified',coalesce(e.tier=2,false),
     'post_count',(select count(*) from public.kaisa_feed_posts p where p.author_id=r.user_id)
   ) from public.resident_profiles r
   left join public.kaisa_entitlements e on e.user_id=r.user_id
   where r.user_id=p_user_id
 ) end;
$$;
revoke all on function public.kaisa_public_profile(uuid) from public;
grant execute on function public.kaisa_public_profile(uuid) to authenticated;

-- A person's already-public feed posts; do not expose private profile fields.
create or replace function public.kaisa_public_profile_posts(p_user_id uuid) returns jsonb
language sql stable security definer set search_path='' as $$
 select case when auth.uid() is null then '[]'::jsonb else
 coalesce(jsonb_agg(jsonb_build_object(
   'id',p.id,'body',p.body,'category',p.category,'created_at',p.created_at,
   'images',coalesce((select jsonb_agg(i.storage_path order by i.position) from public.kaisa_feed_images i where i.post_id=p.id),'[]'::jsonb),
   'likes',(select count(*) from public.kaisa_feed_likes l where l.post_id=p.id),
   'comments',(select count(*) from public.kaisa_feed_comments c where c.post_id=p.id)
 ) order by p.created_at desc),'[]'::jsonb) end
 from (select * from public.kaisa_feed_posts where author_id=p_user_id order by created_at desc limit 40) p;
$$;
revoke all on function public.kaisa_public_profile_posts(uuid) from public;
grant execute on function public.kaisa_public_profile_posts(uuid) to authenticated;

-- Direct messaging: only sender and recipient may read; a sender cannot impersonate others.
create table if not exists public.kaisa_direct_messages (
 id uuid primary key default gen_random_uuid(),
 sender_id uuid not null references auth.users(id) on delete cascade,
 recipient_id uuid not null references auth.users(id) on delete cascade,
 body text not null check (char_length(btrim(body)) between 1 and 1000),
 created_at timestamptz not null default now(),
 check (sender_id<>recipient_id)
);
create index if not exists kaisa_dm_pair_idx on public.kaisa_direct_messages(sender_id,recipient_id,created_at desc);
create index if not exists kaisa_dm_inbox_idx on public.kaisa_direct_messages(recipient_id,created_at desc);
alter table public.kaisa_direct_messages enable row level security;
revoke all on public.kaisa_direct_messages from anon,authenticated;
grant select,insert on public.kaisa_direct_messages to authenticated;
drop policy if exists kaisa_dm_read on public.kaisa_direct_messages;
create policy kaisa_dm_read on public.kaisa_direct_messages for select to authenticated
using(sender_id=(select auth.uid()) or recipient_id=(select auth.uid()));
drop policy if exists kaisa_dm_send on public.kaisa_direct_messages;
create policy kaisa_dm_send on public.kaisa_direct_messages for insert to authenticated
with check (sender_id=(select auth.uid()) and recipient_id<>(select auth.uid()));

-- A resident sees their own attendance/certificate metadata. LGU/service-role issues certificates.
create table if not exists public.kaisa_resident_certificates (
 id uuid primary key default gen_random_uuid(),
 resident_id uuid not null references auth.users(id) on delete cascade,
 event_id uuid references public.kaisa_events(id) on delete set null,
 title text not null,
 storage_path text, -- PRIVATE bucket; use signed URLs via a secure admin-approved download flow
 issued_at timestamptz not null default now()
);
alter table public.kaisa_resident_certificates enable row level security;
revoke all on public.kaisa_resident_certificates from anon, authenticated;
grant select on public.kaisa_resident_certificates to authenticated;
drop policy if exists kaisa_cert_read_own on public.kaisa_resident_certificates;
create policy kaisa_cert_read_own on public.kaisa_resident_certificates for select to authenticated
using(resident_id=(select auth.uid()));

-- Public-safe list of residents who liked a post, for clickable avatars.
create or replace function public.kaisa_post_likers(p_post_id uuid) returns jsonb
language sql stable security definer set search_path='' as $$
 select case when auth.uid() is null then '[]'::jsonb else
 coalesce(jsonb_agg(jsonb_build_object(
   'user_id',l.user_id,
   'display_name',coalesce(nullif(btrim(concat_ws(' ',r.first_name,r.last_name)),''),nullif(r.full_name,''),'KAISA Resident'),
   'avatar_path',r.avatar_path
 ) order by l.created_at desc),'[]'::jsonb) end
 from (select * from public.kaisa_feed_likes where post_id=p_post_id order by created_at desc limit 100) l
 left join public.resident_profiles r on r.user_id=l.user_id;
$$;
revoke all on function public.kaisa_post_likers(uuid) from public;
grant execute on function public.kaisa_post_likers(uuid) to authenticated;
