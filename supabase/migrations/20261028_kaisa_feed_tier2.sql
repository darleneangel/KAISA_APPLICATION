-- KAISA v1. Review existing objects/policies before running on production.
-- Critical: keep tier/role OUT of client-writable resident_profiles and auth user_metadata.
create extension if not exists pgcrypto;

create table if not exists public.kaisa_entitlements (
  user_id uuid primary key references auth.users(id) on delete cascade,
  tier smallint not null default 1 check (tier in (1,2)),
  is_super_admin boolean not null default false,
  approved_at timestamptz,
  approved_by uuid references auth.users(id)
);
alter table public.kaisa_entitlements enable row level security;
revoke all on public.kaisa_entitlements from anon, authenticated;
grant select on public.kaisa_entitlements to authenticated;
drop policy if exists kaisa_entitlement_read_own on public.kaisa_entitlements;
create policy kaisa_entitlement_read_own on public.kaisa_entitlements for select to authenticated using (user_id=auth.uid());
-- Explicitly no authenticated INSERT/UPDATE/DELETE policies.

create or replace function public.kaisa_is_tier2(p_uid uuid default auth.uid()) returns boolean
language sql stable security definer set search_path = '' as $$
 select exists (select 1 from public.kaisa_entitlements where user_id=p_uid and tier=2);
$$;
create or replace function public.kaisa_is_super_admin(p_uid uuid default auth.uid()) returns boolean
language sql stable security definer set search_path = '' as $$
 select exists (select 1 from public.kaisa_entitlements where user_id=p_uid and is_super_admin=true);
$$;
revoke all on function public.kaisa_is_tier2(uuid),public.kaisa_is_super_admin(uuid) from public;
grant execute on function public.kaisa_is_tier2(uuid),public.kaisa_is_super_admin(uuid) to authenticated;

create table if not exists public.kaisa_feed_posts (
 id uuid primary key default gen_random_uuid(),
 author_id uuid not null references auth.users(id) on delete cascade,
 body text not null check (char_length(btrim(body)) between 1 and 2000),
 category text not null default 'Community' check(category in ('Community','Announcement','Event','Organization')),
 created_at timestamptz not null default now()
);
create index if not exists kaisa_feed_recent_idx on public.kaisa_feed_posts(created_at desc);
create table if not exists public.kaisa_feed_images (
 id uuid primary key default gen_random_uuid(),
 post_id uuid not null references public.kaisa_feed_posts(id) on delete cascade,
 owner_id uuid not null references auth.users(id),
 storage_path text not null unique,
 position smallint not null check(position in (1,2)),
 unique(post_id,position)
);
create table if not exists public.kaisa_feed_likes (
 post_id uuid not null references public.kaisa_feed_posts(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 created_at timestamptz not null default now(),
 primary key(post_id,user_id)
);
create table if not exists public.kaisa_feed_comments (
 id uuid primary key default gen_random_uuid(),
 post_id uuid not null references public.kaisa_feed_posts(id) on delete cascade,
 author_id uuid not null references auth.users(id) on delete cascade,
 body text not null check(char_length(btrim(body)) between 1 and 500),
 created_at timestamptz not null default now()
);
create index if not exists kaisa_comments_post_idx on public.kaisa_feed_comments(post_id,created_at);

-- Feed media: public viewing, uploads restricted to owner's UUID folder and tier 2.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('kaisa-feed','kaisa-feed',true,204800,array['image/jpeg','image/png','image/webp'])
on conflict(id) do update set public=true,file_size_limit=204800,allowed_mime_types=excluded.allowed_mime_types;
-- ID media: private, not eligible for public URLs. 5MB limit for legibility.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('kaisa-identity','kaisa-identity',false,5242880,array['image/jpeg','image/png','image/webp'])
on conflict(id) do update set public=false,file_size_limit=5242880,allowed_mime_types=excluded.allowed_mime_types;

-- Needed for the authenticated uploader to verify their uploaded object in
-- kaisa_feed_images_insert; feed bucket is public by design.
drop policy if exists kaisa_feed_object_read on storage.objects;
create policy kaisa_feed_object_read on storage.objects for select to authenticated
using (bucket_id='kaisa-feed');
drop policy if exists kaisa_feed_upload on storage.objects;
create policy kaisa_feed_upload on storage.objects for insert to authenticated
with check (bucket_id='kaisa-feed' and (storage.foldername(name))[1]=auth.uid()::text and public.kaisa_is_tier2());
drop policy if exists kaisa_identity_upload on storage.objects;
create policy kaisa_identity_upload on storage.objects for insert to authenticated
with check (bucket_id='kaisa-identity' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists kaisa_identity_read on storage.objects;
create policy kaisa_identity_read on storage.objects for select to authenticated
using(bucket_id='kaisa-identity' and ((storage.foldername(name))[1]=auth.uid()::text or public.kaisa_is_super_admin()));
-- No client-side public delete/update policy for identity documents.

alter table public.kaisa_feed_posts enable row level security;
alter table public.kaisa_feed_images enable row level security;
alter table public.kaisa_feed_likes enable row level security;
alter table public.kaisa_feed_comments enable row level security;
grant select,insert,delete on public.kaisa_feed_posts,public.kaisa_feed_images,public.kaisa_feed_likes,public.kaisa_feed_comments to authenticated;
-- Do not grant UPDATE on posts or image records; future edits need server-side moderation.

drop policy if exists kaisa_feed_posts_read on public.kaisa_feed_posts;
create policy kaisa_feed_posts_read on public.kaisa_feed_posts for select to authenticated using(true);
drop policy if exists kaisa_feed_posts_insert on public.kaisa_feed_posts;
create policy kaisa_feed_posts_insert on public.kaisa_feed_posts for insert to authenticated
with check(author_id=auth.uid() and public.kaisa_is_tier2());
drop policy if exists kaisa_feed_posts_delete on public.kaisa_feed_posts;
create policy kaisa_feed_posts_delete on public.kaisa_feed_posts for delete to authenticated
using(author_id=auth.uid() or public.kaisa_is_super_admin());

drop policy if exists kaisa_feed_images_read on public.kaisa_feed_images;
create policy kaisa_feed_images_read on public.kaisa_feed_images for select to authenticated using(true);
drop policy if exists kaisa_feed_images_insert on public.kaisa_feed_images;
create policy kaisa_feed_images_insert on public.kaisa_feed_images for insert to authenticated
with check(owner_id=auth.uid() and public.kaisa_is_tier2() and position in (1,2)
  and exists(select 1 from public.kaisa_feed_posts p where p.id=post_id and p.author_id=auth.uid())
  and split_part(storage_path,'/',1)=auth.uid()::text
  and exists(select 1 from storage.objects s where s.bucket_id='kaisa-feed' and s.name=storage_path and s.owner_id=auth.uid()::text));
-- Note: storage.objects.owner_id is text in standard Supabase Storage installations.

drop policy if exists kaisa_feed_likes_read on public.kaisa_feed_likes;
create policy kaisa_feed_likes_read on public.kaisa_feed_likes for select to authenticated using(true);
drop policy if exists kaisa_feed_likes_insert on public.kaisa_feed_likes;
create policy kaisa_feed_likes_insert on public.kaisa_feed_likes for insert to authenticated with check(user_id=auth.uid());
drop policy if exists kaisa_feed_likes_delete on public.kaisa_feed_likes;
create policy kaisa_feed_likes_delete on public.kaisa_feed_likes for delete to authenticated using(user_id=auth.uid());
drop policy if exists kaisa_feed_comments_read on public.kaisa_feed_comments;
create policy kaisa_feed_comments_read on public.kaisa_feed_comments for select to authenticated using(true);
drop policy if exists kaisa_feed_comments_insert on public.kaisa_feed_comments;
create policy kaisa_feed_comments_insert on public.kaisa_feed_comments for insert to authenticated with check(author_id=auth.uid());
drop policy if exists kaisa_feed_comments_delete on public.kaisa_feed_comments;
create policy kaisa_feed_comments_delete on public.kaisa_feed_comments for delete to authenticated
using(author_id=auth.uid() or public.kaisa_is_super_admin());

-- Limited public-facing identity: never expose addresses, mobile or ID documents to feed readers.
create or replace function public.kaisa_feed_stream() returns jsonb
language sql stable security definer set search_path='' as $$
 select coalesce(jsonb_agg(jsonb_build_object(
 'id',p.id,'author_id',p.author_id,'body',p.body,'category',p.category,'created_at',p.created_at,
 'author_name',coalesce(nullif(btrim(concat_ws(' ',r.first_name,r.last_name)),''),'KAISA Resident'),
 'images',coalesce((select jsonb_agg(i.storage_path order by i.position) from public.kaisa_feed_images i where i.post_id=p.id),'[]'::jsonb),
 'likes',(select count(*) from public.kaisa_feed_likes l where l.post_id=p.id),
 'comments',(select count(*) from public.kaisa_feed_comments c where c.post_id=p.id),
 'liked',exists(select 1 from public.kaisa_feed_likes l where l.post_id=p.id and l.user_id=auth.uid())
 ) order by p.created_at desc),'[]'::jsonb)
 from (select * from public.kaisa_feed_posts order by created_at desc limit 50) p
 left join public.resident_profiles r on r.user_id=p.author_id;
$$;
create or replace function public.kaisa_feed_comments_for(p_post_id uuid) returns jsonb
language sql stable security definer set search_path='' as $$
 select coalesce(jsonb_agg(jsonb_build_object('id',c.id,'author_id',c.author_id,'body',c.body,
 'created_at',c.created_at,'author_name',coalesce(nullif(btrim(concat_ws(' ',r.first_name,r.last_name)),''),'KAISA Resident')) order by c.created_at),'[]'::jsonb)
 from (select * from public.kaisa_feed_comments where post_id=p_post_id order by created_at asc limit 100) c
 left join public.resident_profiles r on r.user_id=c.author_id;
$$;
revoke all on function public.kaisa_feed_stream(),public.kaisa_feed_comments_for(uuid) from public;
grant execute on function public.kaisa_feed_stream(),public.kaisa_feed_comments_for(uuid) to authenticated;

create table if not exists public.kaisa_identity_requests (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 id_type text not null,
 id_path text not null,
 extracted_name text,
 extracted_address text,
 extracted_text text, -- Sensitive: restrict RLS, consider shorter retention in production
 status text not null default 'pending' check(status in ('pending','approved','rejected')),
 submitted_at timestamptz not null default now(),
 reviewed_by uuid references auth.users(id),
 reviewed_at timestamptz,
 review_note text
);
create unique index if not exists kaisa_one_pending_id on public.kaisa_identity_requests(user_id) where status='pending';
alter table public.kaisa_identity_requests enable row level security;
grant select,insert on public.kaisa_identity_requests to authenticated;
drop policy if exists kaisa_identity_requests_select on public.kaisa_identity_requests;
create policy kaisa_identity_requests_select on public.kaisa_identity_requests for select to authenticated using(user_id=auth.uid() or public.kaisa_is_super_admin());
drop policy if exists kaisa_identity_requests_insert on public.kaisa_identity_requests;
create policy kaisa_identity_requests_insert on public.kaisa_identity_requests for insert to authenticated
with check(user_id=auth.uid() and status='pending' and reviewed_by is null and reviewed_at is null
 and split_part(id_path,'/',1)=auth.uid()::text and exists (
 select 1 from storage.objects so where so.bucket_id='kaisa-identity' and so.name=id_path));
-- Don't grant UPDATE/DELETE to authenticated: OCR updates only via protected service role, review via RPC.

create or replace function public.kaisa_admin_review_identity(p_request_id uuid,p_approve boolean,p_note text default null)
returns void language plpgsql security definer set search_path='' as $$
declare v_target uuid;
begin
 if auth.uid() is null or not public.kaisa_is_super_admin() then
   raise exception 'Only KAISA Super Admins can review identity requests';
 end if;
 select user_id into v_target from public.kaisa_identity_requests where id=p_request_id and status='pending' for update;
 if v_target is null then raise exception 'Pending request not found'; end if;
 update public.kaisa_identity_requests set status=case when p_approve then 'approved' else 'rejected' end,
 reviewed_by=auth.uid(),reviewed_at=now(),review_note=left(p_note,500) where id=p_request_id;
 if p_approve then
  insert into public.kaisa_entitlements(user_id,tier,approved_at,approved_by)
  values(v_target,2,now(),auth.uid()) on conflict(user_id) do update set tier=2,approved_at=now(),approved_by=auth.uid();
 end if;
end;
$$;
revoke all on function public.kaisa_admin_review_identity(uuid,boolean,text) from public;
grant execute on function public.kaisa_admin_review_identity(uuid,boolean,text) to authenticated;

-- Create super admins ONLY in the Supabase SQL Editor AFTER identifying each person's auth.users.id:
-- insert into public.kaisa_entitlements(user_id,is_super_admin)
-- values ('REPLACE_WITH_EXISTING_SUPER_ADMIN_AUTH_UUID',true)
-- on conflict(user_id) do update set is_super_admin=true;

-- OCR suggestion only; retains a short excerpt, not a full identity-document dump.
alter table public.kaisa_identity_requests add column if not exists ocr_preview text;
