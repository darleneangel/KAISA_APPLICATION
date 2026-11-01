-- KAISA SOCIAL V2: run after feed, profile, and entitlements migrations.
-- Test against a backup before using on production.
create table if not exists public.kaisa_friendships (
 id uuid primary key default gen_random_uuid(),
 requester_id uuid not null references auth.users(id) on delete cascade,
 addressee_id uuid not null references auth.users(id) on delete cascade,
 status text not null default 'pending' check (status in ('pending','accepted')),
 created_at timestamptz not null default now(),
 accepted_at timestamptz,
 check (requester_id <> addressee_id)
);
create unique index if not exists kaisa_friendships_one_pair
 on public.kaisa_friendships (least(requester_id, addressee_id), greatest(requester_id, addressee_id));
create index if not exists kaisa_friendships_addressee on public.kaisa_friendships(addressee_id,status);
alter table public.kaisa_friendships enable row level security;
revoke all on public.kaisa_friendships from anon, authenticated;
grant select on public.kaisa_friendships to authenticated;
drop policy if exists kaisa_friendships_own on public.kaisa_friendships;
create policy kaisa_friendships_own on public.kaisa_friendships for select to authenticated
 using (requester_id=auth.uid() or addressee_id=auth.uid());

create or replace function public.kaisa_are_friends(p_a uuid,p_b uuid) returns boolean
 language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.kaisa_friendships f where f.status='accepted'
 and ((f.requester_id=p_a and f.addressee_id=p_b) or (f.requester_id=p_b and f.addressee_id=p_a)));
$$;
revoke all on function public.kaisa_are_friends(uuid,uuid) from public;
grant execute on function public.kaisa_are_friends(uuid,uuid) to authenticated;

create or replace function public.kaisa_friend_action(p_user_id uuid,p_action text) returns text
 language plpgsql security definer set search_path='' as $$
declare v_me uuid:=auth.uid(); v_f public.kaisa_friendships%rowtype;
begin
 if v_me is null or p_user_id is null or v_me=p_user_id then raise exception 'Invalid resident'; end if;
 if not public.kaisa_is_tier2(v_me) or not public.kaisa_is_tier2(p_user_id) then
  raise exception 'Both residents must be Tier 2'; end if;
 if p_action='request' then
  if not exists(select 1 from auth.users where id=p_user_id) then raise exception 'Resident not found'; end if;
  insert into public.kaisa_friendships(requester_id,addressee_id) values(v_me,p_user_id)
  on conflict do nothing;
  return 'pending';
 end if;
 select * into v_f from public.kaisa_friendships
 where (requester_id=v_me and addressee_id=p_user_id)
 or (requester_id=p_user_id and addressee_id=v_me) for update;
 if v_f.id is null then raise exception 'Friend request not found'; end if;
 if p_action='accept' then
  if v_f.addressee_id<>v_me or v_f.status<>'pending' then raise exception 'Only recipient may accept'; end if;
  update public.kaisa_friendships set status='accepted',accepted_at=now() where id=v_f.id;
  return 'accepted';
 elsif p_action='remove' then
  delete from public.kaisa_friendships where id=v_f.id;
  return 'removed';
 end if;
 raise exception 'Unknown action';
end;
$$;
revoke all on function public.kaisa_friend_action(uuid,text) from public;
grant execute on function public.kaisa_friend_action(uuid,text) to authenticated;

create or replace function public.kaisa_my_friendships() returns jsonb
 language sql stable security definer set search_path='' as $$
 select coalesce(jsonb_agg(jsonb_build_object(
 'id',f.id,'other_id',case when f.requester_id=auth.uid() then f.addressee_id else f.requester_id end,
 'status',f.status,'incoming',f.addressee_id=auth.uid(),
 'name',coalesce(nullif(btrim(concat_ws(' ',r.first_name,r.last_name)),''),'KAISA Resident'),
 'avatar_path',r.avatar_path
 ) order by f.created_at desc),'[]'::jsonb)
 from public.kaisa_friendships f
 left join public.resident_profiles r on r.user_id=case when f.requester_id=auth.uid() then f.addressee_id else f.requester_id end
 where auth.uid() is not null and (f.requester_id=auth.uid() or f.addressee_id=auth.uid());
$$;
revoke all on function public.kaisa_my_friendships() from public;
grant execute on function public.kaisa_my_friendships() to authenticated;

alter table public.kaisa_feed_posts add column if not exists visibility text not null default 'public';
alter table public.kaisa_feed_posts drop constraint if exists kaisa_feed_posts_visibility_check;
alter table public.kaisa_feed_posts add constraint kaisa_feed_posts_visibility_check check(visibility in('public','friends','private'));
alter table public.kaisa_feed_posts add column if not exists shared_post_id uuid references public.kaisa_feed_posts(id) on delete set null;

create or replace function public.kaisa_can_view_post(p_post_id uuid,p_viewer uuid default auth.uid()) returns boolean
 language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.kaisa_feed_posts p where p.id=p_post_id and p_viewer is not null and
 (p.author_id=p_viewer or p.visibility='public' or
 (p.visibility='friends' and public.kaisa_are_friends(p.author_id,p_viewer)))
 and (p.shared_post_id is null or exists(select 1 from public.kaisa_feed_posts original
 where original.id=p.shared_post_id and (original.author_id=p_viewer or original.visibility='public'
 or (original.visibility='friends' and public.kaisa_are_friends(original.author_id,p_viewer))))));
$$;
revoke all on function public.kaisa_can_view_post(uuid,uuid) from public;
grant execute on function public.kaisa_can_view_post(uuid,uuid) to authenticated;

-- Remove previous broad read policies before adding restrictive visibility rules.
drop policy if exists kaisa_feed_posts_read on public.kaisa_feed_posts;
create policy kaisa_feed_posts_read on public.kaisa_feed_posts for select to authenticated
 using(public.kaisa_can_view_post(id,auth.uid()));
drop policy if exists kaisa_feed_posts_insert on public.kaisa_feed_posts;
create policy kaisa_feed_posts_insert on public.kaisa_feed_posts for insert to authenticated
 with check(author_id=auth.uid() and public.kaisa_is_tier2() and
 (shared_post_id is null or (visibility<>'private' and public.kaisa_can_view_post(shared_post_id,auth.uid()))));

-- Existing feed images live in a public bucket; disallow new uploads attached to nonpublic posts.
drop policy if exists kaisa_feed_images_read on public.kaisa_feed_images;
create policy kaisa_feed_images_read on public.kaisa_feed_images for select to authenticated
 using(public.kaisa_can_view_post(post_id,auth.uid()));
drop policy if exists kaisa_feed_images_insert on public.kaisa_feed_images;
create policy kaisa_feed_images_insert on public.kaisa_feed_images for insert to authenticated
 with check(owner_id=auth.uid() and public.kaisa_is_tier2()
 and split_part(storage_path,'/',1)=auth.uid()::text
 and exists(select 1 from public.kaisa_feed_posts p where p.id=post_id
 and p.author_id=auth.uid() and p.visibility='public')
 and exists(select 1 from storage.objects s where s.bucket_id='kaisa-feed'
 and s.name=storage_path and s.owner_id=auth.uid()::text));

-- Tier 1 is read-only, and likes/comments must belong to posts the resident may view.
drop policy if exists kaisa_feed_likes_read on public.kaisa_feed_likes;
create policy kaisa_feed_likes_read on public.kaisa_feed_likes for select to authenticated
 using(public.kaisa_can_view_post(post_id,auth.uid()));
drop policy if exists kaisa_feed_likes_insert on public.kaisa_feed_likes;
create policy kaisa_feed_likes_insert on public.kaisa_feed_likes for insert to authenticated
 with check(user_id=auth.uid() and public.kaisa_is_tier2() and public.kaisa_can_view_post(post_id,auth.uid()));
drop policy if exists kaisa_feed_likes_delete on public.kaisa_feed_likes;
create policy kaisa_feed_likes_delete on public.kaisa_feed_likes for delete to authenticated
 using(user_id=auth.uid() and public.kaisa_is_tier2());
drop policy if exists kaisa_feed_comments_read on public.kaisa_feed_comments;
create policy kaisa_feed_comments_read on public.kaisa_feed_comments for select to authenticated
 using(public.kaisa_can_view_post(post_id,auth.uid()));
drop policy if exists kaisa_feed_comments_insert on public.kaisa_feed_comments;
create policy kaisa_feed_comments_insert on public.kaisa_feed_comments for insert to authenticated
 with check(author_id=auth.uid() and public.kaisa_is_tier2() and public.kaisa_can_view_post(post_id,auth.uid()));
drop policy if exists kaisa_feed_comments_delete on public.kaisa_feed_comments;
create policy kaisa_feed_comments_delete on public.kaisa_feed_comments for delete to authenticated
 using(author_id=auth.uid() and public.kaisa_is_tier2());

create or replace function public.kaisa_feed_stream() returns jsonb
 language sql stable security definer set search_path='' as $$
 select coalesce(jsonb_agg(jsonb_build_object(
 'id',p.id,'author_id',p.author_id,'body',p.body,'category',p.category,'visibility',p.visibility,
 'shared_post_id',p.shared_post_id,
 'shared_body',orig.body,'shared_author_name',coalesce(nullif(btrim(concat_ws(' ',op.first_name,op.last_name)),''),'KAISA Resident'),
 'created_at',p.created_at,
 'author_name',coalesce(nullif(btrim(concat_ws(' ',r.first_name,r.last_name)),''),'KAISA Resident'),
 'images',coalesce((select jsonb_agg(i.storage_path order by i.position) from public.kaisa_feed_images i where i.post_id=p.id),'[]'::jsonb),
 'likes',(select count(*) from public.kaisa_feed_likes l where l.post_id=p.id),
 'comments',(select count(*) from public.kaisa_feed_comments c where c.post_id=p.id),
 'liked',exists(select 1 from public.kaisa_feed_likes l where l.post_id=p.id and l.user_id=auth.uid())
 ) order by p.created_at desc),'[]'::jsonb)
 from (select * from public.kaisa_feed_posts where auth.uid() is not null
 and public.kaisa_can_view_post(id,auth.uid()) order by created_at desc limit 80) p
 left join public.resident_profiles r on r.user_id=p.author_id
 left join public.kaisa_feed_posts orig on orig.id=p.shared_post_id
 left join public.resident_profiles op on op.user_id=orig.author_id;
$$;

create or replace function public.kaisa_feed_comments_for(p_post_id uuid) returns jsonb
 language sql stable security definer set search_path='' as $$
 select case when public.kaisa_can_view_post(p_post_id,auth.uid()) then
 coalesce(jsonb_agg(jsonb_build_object('id',c.id,'author_id',c.author_id,'body',c.body,
 'created_at',c.created_at,'author_name',coalesce(nullif(btrim(concat_ws(' ',r.first_name,r.last_name)),''),'KAISA Resident'))
 order by c.created_at),'[]'::jsonb) else '[]'::jsonb end
 from (select * from public.kaisa_feed_comments where post_id=p_post_id order by created_at limit 100) c
 left join public.resident_profiles r on r.user_id=c.author_id;
$$;
create or replace function public.kaisa_post_likers(p_post_id uuid) returns jsonb
 language sql stable security definer set search_path='' as $$
 select case when public.kaisa_can_view_post(p_post_id,auth.uid()) then
 coalesce(jsonb_agg(jsonb_build_object('user_id',l.user_id,
 'display_name',coalesce(nullif(btrim(concat_ws(' ',r.first_name,r.last_name)),''),'KAISA Resident'),
 'avatar_path',r.avatar_path) order by l.created_at desc),'[]'::jsonb) else '[]'::jsonb end
 from (select * from public.kaisa_feed_likes where post_id=p_post_id order by created_at desc limit 100) l
 left join public.resident_profiles r on r.user_id=l.user_id;
$$;
create or replace function public.kaisa_public_profile_posts(p_user_id uuid) returns jsonb
 language sql stable security definer set search_path='' as $$
 select coalesce(jsonb_agg(jsonb_build_object('id',p.id,'body',p.body,'category',p.category,
 'visibility',p.visibility,'created_at',p.created_at,
 'images',coalesce((select jsonb_agg(i.storage_path order by i.position) from public.kaisa_feed_images i where i.post_id=p.id),'[]'::jsonb),
 'likes',(select count(*) from public.kaisa_feed_likes l where l.post_id=p.id),
 'comments',(select count(*) from public.kaisa_feed_comments c where c.post_id=p.id)
 ) order by p.created_at desc),'[]'::jsonb)
 from (select * from public.kaisa_feed_posts where author_id=p_user_id
 and auth.uid() is not null and public.kaisa_can_view_post(id,auth.uid())
 order by created_at desc limit 40) p;
$$;

-- Shares are real Feed posts referencing their source, never editable impersonations.
create or replace function public.kaisa_share_to_feed(p_post_id uuid,p_message text,p_visibility text)
 returns uuid language plpgsql security definer set search_path='' as $$
declare v_id uuid; v_source public.kaisa_feed_posts%rowtype;
begin
 if auth.uid() is null or not public.kaisa_is_tier2() then raise exception 'Tier 2 required'; end if;
 if p_visibility not in ('public','friends') then raise exception 'Choose Public or Friends'; end if;
 select * into v_source from public.kaisa_feed_posts where id=p_post_id;
 if v_source.id is null or v_source.shared_post_id is not null or v_source.visibility='private'
 or not public.kaisa_can_view_post(p_post_id,auth.uid()) then raise exception 'Post cannot be shared'; end if;
 if char_length(btrim(coalesce(p_message,'')))>500 then raise exception 'Share note too long'; end if;
 insert into public.kaisa_feed_posts(author_id,body,category,visibility,shared_post_id)
 values(auth.uid(),coalesce(nullif(btrim(p_message),''),'Shared a community post'),v_source.category,p_visibility,p_post_id)
 returning id into v_id;
 return v_id;
end;
$$;
revoke all on function public.kaisa_share_to_feed(uuid,text,text) from public;
grant execute on function public.kaisa_share_to_feed(uuid,text,text) to authenticated;

-- Stories. Private storage: image paths never become permanent public URLs.
create table if not exists public.kaisa_stories (
 id uuid primary key default gen_random_uuid(),
 author_id uuid not null references auth.users(id) on delete cascade,
 caption text not null default '' check(char_length(caption)<=500),
 image_path text,
 visibility text not null default 'public' check(visibility in ('public','friends','private')),
 created_at timestamptz not null default now(),
 expires_at timestamptz not null default (now()+interval '24 hours'),
 check(image_path is not null or char_length(btrim(caption))>0),
 check(expires_at<=created_at+interval '24 hours' and expires_at>created_at)
);
create index if not exists kaisa_stories_recent on public.kaisa_stories(expires_at desc);
alter table public.kaisa_stories enable row level security;
revoke all on public.kaisa_stories from anon,authenticated;
grant select,insert,delete on public.kaisa_stories to authenticated;
create or replace function public.kaisa_can_view_story(p_story_id uuid,p_viewer uuid default auth.uid()) returns boolean
 language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.kaisa_stories s where s.id=p_story_id and p_viewer is not null and s.expires_at>now()
 and (s.author_id=p_viewer or s.visibility='public'
 or (s.visibility='friends' and public.kaisa_are_friends(s.author_id,p_viewer))));
$$;
revoke all on function public.kaisa_can_view_story(uuid,uuid) from public;
grant execute on function public.kaisa_can_view_story(uuid,uuid) to authenticated;
drop policy if exists kaisa_stories_read on public.kaisa_stories;
create policy kaisa_stories_read on public.kaisa_stories for select to authenticated
 using(public.kaisa_can_view_story(id,auth.uid()));
drop policy if exists kaisa_stories_write on public.kaisa_stories;
create policy kaisa_stories_write on public.kaisa_stories for insert to authenticated
 with check(author_id=auth.uid() and public.kaisa_is_tier2()
 and created_at between now()-interval '1 minute' and now()+interval '1 minute'
 and expires_at<=created_at+interval '24 hours'
 and (image_path is null or split_part(image_path,'/',1)=auth.uid()::text));
drop policy if exists kaisa_stories_delete on public.kaisa_stories;
create policy kaisa_stories_delete on public.kaisa_stories for delete to authenticated using(author_id=auth.uid());
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
 values('kaisa-stories','kaisa-stories',false,2097152,array['image/jpeg','image/png','image/webp'])
 on conflict(id) do update set public=false,file_size_limit=2097152,allowed_mime_types=excluded.allowed_mime_types;
drop policy if exists kaisa_stories_media_upload on storage.objects;
create policy kaisa_stories_media_upload on storage.objects for insert to authenticated
 with check(bucket_id='kaisa-stories' and (storage.foldername(name))[1]=auth.uid()::text and public.kaisa_is_tier2());
drop policy if exists kaisa_stories_media_read on storage.objects;
create policy kaisa_stories_media_read on storage.objects for select to authenticated
 using(bucket_id='kaisa-stories' and ((storage.foldername(name))[1]=auth.uid()::text
 or exists(select 1 from public.kaisa_stories s where s.image_path=name
 and public.kaisa_can_view_story(s.id,auth.uid()))));
drop policy if exists kaisa_stories_media_delete on storage.objects;
create policy kaisa_stories_media_delete on storage.objects for delete to authenticated
 using(bucket_id='kaisa-stories' and (storage.foldername(name))[1]=auth.uid()::text);
create or replace function public.kaisa_active_stories() returns jsonb
 language sql stable security definer set search_path='' as $$
 select coalesce(jsonb_agg(jsonb_build_object('id',s.id,'author_id',s.author_id,
 'author_name',coalesce(nullif(btrim(concat_ws(' ',r.first_name,r.last_name)),''),'Resident'),
 'caption',s.caption,'image_path',s.image_path,'visibility',s.visibility,
 'created_at',s.created_at,'expires_at',s.expires_at) order by s.created_at desc),'[]'::jsonb)
 from (select * from public.kaisa_stories where auth.uid() is not null
 and public.kaisa_can_view_story(id,auth.uid()) order by created_at desc limit 80) s
 left join public.resident_profiles r on r.user_id=s.author_id;
$$;
revoke all on function public.kaisa_active_stories() from public;
grant execute on function public.kaisa_active_stories() to authenticated;

-- Note: scheduled cleanup of expired story rows/media should be configured server-side.
-- The visibility rule above hides expired stories immediately, regardless of cleanup timing.
