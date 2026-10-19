-- Sprint 1: profiles table, auto-create on sign-up, and RLS.
-- Run this in Supabase Dashboard -> SQL Editor.

create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  full_name   text not null default '',
  role        text not null default 'employee'
              check (role in ('employee', 'technician', 'manager')),
  site_id     uuid,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- Returns the role of the logged-in user (used by policies on every table).
create or replace function public.my_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid()
$$;

-- Everyone can read their own profile; managers can read all profiles.
drop policy if exists "read own profile or manager reads all" on public.profiles;
create policy "read own profile or manager reads all"
on public.profiles for select
using (id = auth.uid() or public.my_role() = 'manager');

-- Only managers can change profiles (e.g. a user's role).
drop policy if exists "managers update profiles" on public.profiles;
create policy "managers update profiles"
on public.profiles for update
using (public.my_role() = 'manager');

-- Create a profile row automatically when someone signs up.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', ''));
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Keep updated_at accurate whenever a profile changes.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- Bootstrap: nobody can promote the first manager through the app (only managers
-- can change roles), so do it once by hand in the SQL Editor:
--   update public.profiles set role = 'manager' where id = '<user uuid>';
