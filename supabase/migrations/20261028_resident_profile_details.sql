-- KAISA resident profiles. Apply once in Supabase SQL Editor.
-- Does NOT drop or overwrite your existing auth.users or social OTP tables.
create table if not exists public.resident_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  last_name text,
  first_name text,
  middle_name text,
  full_name text,
  birth_date date,
  gender text,
  mobile_number text,
  province text,
  city_municipality text,
  barangay text,
  street_address text,
  zip_code text,
  interests text[] not null default '{}',
  skills text[] not null default '{}',
  profile_completed boolean not null default false,
  resident_tier integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint resident_zip_four_digits check (zip_code is null or zip_code ~ '^[0-9]{4}$')
);

-- If resident_profiles already exists, add missing fields without deleting data.
alter table public.resident_profiles
  add column if not exists last_name text,
  add column if not exists first_name text,
  add column if not exists middle_name text,
  add column if not exists full_name text,
  add column if not exists birth_date date,
  add column if not exists gender text,
  add column if not exists mobile_number text,
  add column if not exists province text,
  add column if not exists city_municipality text,
  add column if not exists barangay text,
  add column if not exists street_address text,
  add column if not exists zip_code text,
  add column if not exists interests text[] not null default '{}',
  add column if not exists skills text[] not null default '{}',
  add column if not exists profile_completed boolean not null default false,
  add column if not exists resident_tier integer not null default 1,
  add column if not exists updated_at timestamptz not null default now();

alter table public.resident_profiles enable row level security;

grant select, insert, update on public.resident_profiles to authenticated;

-- Only the account owner can read or edit their own resident profile.
drop policy if exists "resident select own" on public.resident_profiles;
create policy "resident select own" on public.resident_profiles
  for select to authenticated using ((select auth.uid()) = id);

drop policy if exists "resident insert own" on public.resident_profiles;
create policy "resident insert own" on public.resident_profiles
  for insert to authenticated with check ((select auth.uid()) = id);

drop policy if exists "resident update own" on public.resident_profiles;
create policy "resident update own" on public.resident_profiles
  for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- IMPORTANT FOR PRODUCTION: resident_tier/profile_completed in a user-writable
-- table or user_metadata must NOT be trusted to grant privileged access.
-- Define verified tier and roles in separately protected, admin-managed tables.
