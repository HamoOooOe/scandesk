-- Sprint 2: sites, locations and assets, with RLS and an automatic asset code.
-- Run this in Supabase Dashboard -> SQL Editor (after 0001).
-- Everyone signed in can read; only managers can create, change or delete.

create table if not exists public.sites (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  city        text not null default '',
  created_at  timestamptz not null default now()
);

create table if not exists public.locations (
  id          uuid primary key default gen_random_uuid(),
  site_id     uuid not null references public.sites (id) on delete cascade,
  name        text not null,
  created_at  timestamptz not null default now()
);

create table if not exists public.assets (
  id              uuid primary key default gen_random_uuid(),
  code            text not null unique,
  name            text not null,
  category        text not null default 'other'
                  check (category in ('laptop','desktop','monitor','printer','phone','network','other')),
  status          text not null default 'active'
                  check (status in ('active','in_repair','storage','retired')),
  brand           text not null default '',
  model           text not null default '',
  serial          text not null default '',
  site_id         uuid references public.sites (id) on delete set null,
  location_id     uuid references public.locations (id) on delete set null,
  assigned_to     text not null default '',
  purchase_date   date,
  warranty_until  date,
  notes           text not null default '',
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists assets_site_idx on public.assets (site_id);
create index if not exists assets_status_idx on public.assets (status);
create index if not exists locations_site_idx on public.locations (site_id);

-- Asset codes: LAP-0001, LAP-0002, ... one counter per prefix.
create table if not exists public.asset_counters (
  prefix  text primary key,
  last    integer not null default 0
);

create or replace function public.next_asset_code(p_category text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_prefix text := case p_category
    when 'laptop'  then 'LAP'
    when 'desktop' then 'DSK'
    when 'monitor' then 'MON'
    when 'printer' then 'PRT'
    when 'phone'   then 'PHN'
    when 'network' then 'NET'
    else 'OTH'
  end;
  v_next integer;
begin
  -- The upsert locks the counter row, so two managers saving at the same
  -- moment can never get the same number.
  insert into public.asset_counters as c (prefix, last) values (v_prefix, 1)
  on conflict (prefix) do update set last = c.last + 1
  returning last into v_next;
  return v_prefix || '-' || lpad(v_next::text, 4, '0');
end;
$$;

create or replace function public.assets_before_insert()
returns trigger
language plpgsql
as $$
begin
  if new.code is null or new.code = '' then
    new.code := public.next_asset_code(new.category);
  end if;
  return new;
end;
$$;

drop trigger if exists assets_set_code on public.assets;
create trigger assets_set_code
  before insert on public.assets
  for each row execute function public.assets_before_insert();

drop trigger if exists assets_set_updated_at on public.assets;
create trigger assets_set_updated_at
  before update on public.assets
  for each row execute function public.set_updated_at();

-- The code column is NOT NULL, but the app sends none. Allow an empty
-- insert value by defaulting to '' so the trigger can replace it.
alter table public.assets alter column code set default '';

-- Row level security.
alter table public.sites enable row level security;
alter table public.locations enable row level security;
alter table public.assets enable row level security;
alter table public.asset_counters enable row level security;

drop policy if exists "signed in users read sites" on public.sites;
create policy "signed in users read sites" on public.sites
  for select to authenticated using (true);
drop policy if exists "managers write sites" on public.sites;
create policy "managers write sites" on public.sites
  for all to authenticated
  using (public.my_role() = 'manager') with check (public.my_role() = 'manager');

drop policy if exists "signed in users read locations" on public.locations;
create policy "signed in users read locations" on public.locations
  for select to authenticated using (true);
drop policy if exists "managers write locations" on public.locations;
create policy "managers write locations" on public.locations
  for all to authenticated
  using (public.my_role() = 'manager') with check (public.my_role() = 'manager');

drop policy if exists "signed in users read assets" on public.assets;
create policy "signed in users read assets" on public.assets
  for select to authenticated using (true);
drop policy if exists "managers write assets" on public.assets;
create policy "managers write assets" on public.assets
  for all to authenticated
  using (public.my_role() = 'manager') with check (public.my_role() = 'manager');

-- No policy on asset_counters: nobody reaches it directly, only the
-- security definer function above.
