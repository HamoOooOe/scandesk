-- Sprints 4 and 5: tickets, photos, work logs, status rules, Storage, Realtime.
-- Run this in Supabase Dashboard -> SQL Editor (after 0002).

create table if not exists public.tickets (
  id           uuid primary key default gen_random_uuid(),
  asset_id     uuid not null references public.assets (id) on delete cascade,
  title        text not null check (char_length(title) between 3 and 140),
  description  text not null default '',
  status       text not null default 'open'
               check (status in ('open','assigned','in_progress','resolved')),
  priority     text not null default 'medium'
               check (priority in ('low','medium','high')),
  reporter_id  uuid not null default auth.uid() references auth.users (id),
  assignee_id  uuid references auth.users (id),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create table if not exists public.ticket_photos (
  id          uuid primary key default gen_random_uuid(),
  ticket_id   uuid not null references public.tickets (id) on delete cascade,
  path        text not null,
  created_at  timestamptz not null default now()
);

create table if not exists public.work_logs (
  id          uuid primary key default gen_random_uuid(),
  ticket_id   uuid not null references public.tickets (id) on delete cascade,
  asset_id    uuid not null references public.assets (id) on delete cascade,
  author_id   uuid not null default auth.uid() references auth.users (id),
  note        text not null check (char_length(note) > 0),
  minutes     integer not null default 0 check (minutes >= 0),
  parts       text not null default '',
  created_at  timestamptz not null default now()
);

create index if not exists tickets_asset_idx on public.tickets (asset_id);
create index if not exists tickets_status_idx on public.tickets (status);
create index if not exists tickets_assignee_idx on public.tickets (assignee_id);
create index if not exists work_logs_asset_idx on public.work_logs (asset_id, created_at desc);
create index if not exists work_logs_ticket_idx on public.work_logs (ticket_id);

-- Status rules (the same as TicketRules in the app, enforced here too):
--   open -> assigned           manager assigns
--   assigned -> assigned       manager re-assigns
--   assigned -> in_progress    the assignee, or a manager
--   in_progress -> resolved    the assignee, or a manager
-- Anything else is refused, so a ticket only moves forward one step.
create or replace function public.tickets_enforce_status()
returns trigger
language plpgsql
as $$
declare
  v_role text := public.my_role();
begin
  new.updated_at := now();

  if new.status = old.status and new.assignee_id is not distinct from old.assignee_id then
    return new;
  end if;

  if new.status = 'assigned' and old.status in ('open', 'assigned') then
    if v_role <> 'manager' then
      raise exception 'only a manager can assign tickets' using errcode = '42501';
    end if;
  elsif old.status = 'assigned' and new.status = 'in_progress' then
    if not (v_role = 'manager' or (v_role = 'technician' and old.assignee_id = auth.uid())) then
      raise exception 'only the assignee can start work' using errcode = '42501';
    end if;
  elsif old.status = 'in_progress' and new.status = 'resolved' then
    if not (v_role = 'manager' or (v_role = 'technician' and old.assignee_id = auth.uid())) then
      raise exception 'only the assignee can resolve' using errcode = '42501';
    end if;
  else
    raise exception 'invalid status change % -> %', old.status, new.status using errcode = '23514';
  end if;

  return new;
end;
$$;

drop trigger if exists tickets_status_guard on public.tickets;
create trigger tickets_status_guard
  before update on public.tickets
  for each row execute function public.tickets_enforce_status();

-- Row level security.
alter table public.tickets enable row level security;
alter table public.ticket_photos enable row level security;
alter table public.work_logs enable row level security;

-- Employees see their own tickets; technicians and managers see all.
drop policy if exists "read tickets" on public.tickets;
create policy "read tickets" on public.tickets
  for select to authenticated
  using (reporter_id = auth.uid() or public.my_role() in ('technician', 'manager'));

-- Anyone signed in can report a problem, as themselves.
drop policy if exists "report tickets" on public.tickets;
create policy "report tickets" on public.tickets
  for insert to authenticated
  with check (reporter_id = auth.uid() and status = 'open' and assignee_id is null);

drop policy if exists "work on tickets" on public.tickets;
create policy "work on tickets" on public.tickets
  for update to authenticated
  using (
    public.my_role() = 'manager'
    or (public.my_role() = 'technician' and assignee_id = auth.uid())
  );

-- Photos and work logs follow the ticket they belong to.
drop policy if exists "read photos" on public.ticket_photos;
create policy "read photos" on public.ticket_photos
  for select to authenticated
  using (exists (select 1 from public.tickets t where t.id = ticket_id));

drop policy if exists "add photos to own tickets" on public.ticket_photos;
create policy "add photos to own tickets" on public.ticket_photos
  for insert to authenticated
  with check (exists (select 1 from public.tickets t where t.id = ticket_id and t.reporter_id = auth.uid()));

drop policy if exists "read work logs" on public.work_logs;
create policy "read work logs" on public.work_logs
  for select to authenticated
  using (exists (select 1 from public.tickets t where t.id = ticket_id));

drop policy if exists "log work" on public.work_logs;
create policy "log work" on public.work_logs
  for insert to authenticated
  with check (
    author_id = auth.uid()
    and (
      public.my_role() = 'manager'
      or (public.my_role() = 'technician'
          and exists (select 1 from public.tickets t where t.id = ticket_id and t.assignee_id = auth.uid()))
    )
  );

-- Views with names. They run with the owner's rights (so they can read
-- profiles) but repeat the ticket visibility rule themselves.
create or replace view public.tickets_view as
select
  t.id, t.asset_id, a.code as asset_code, a.name as asset_name,
  t.title, t.description, t.status, t.priority,
  t.reporter_id, r.full_name as reporter_name,
  t.assignee_id, s.full_name as assignee_name,
  t.created_at, t.updated_at,
  array(select p.path from public.ticket_photos p where p.ticket_id = t.id order by p.created_at) as photo_paths
from public.tickets t
join public.assets a on a.id = t.asset_id
left join public.profiles r on r.id = t.reporter_id
left join public.profiles s on s.id = t.assignee_id
where t.reporter_id = auth.uid() or public.my_role() in ('technician', 'manager');

create or replace view public.work_logs_view as
select
  w.id, w.ticket_id, w.asset_id, w.note, w.minutes, w.parts, w.created_at,
  p.full_name as author_name
from public.work_logs w
join public.tickets t on t.id = w.ticket_id
left join public.profiles p on p.id = w.author_id
where t.reporter_id = auth.uid() or public.my_role() in ('technician', 'manager');

grant select on public.tickets_view, public.work_logs_view to authenticated;

-- Private bucket for ticket photos. Path: <ticket id>/<n>.jpg
insert into storage.buckets (id, name, public)
values ('ticket-photos', 'ticket-photos', false)
on conflict (id) do nothing;

drop policy if exists "upload ticket photos" on storage.objects;
create policy "upload ticket photos" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'ticket-photos');

drop policy if exists "read ticket photos" on storage.objects;
create policy "read ticket photos" on storage.objects
  for select to authenticated
  using (bucket_id = 'ticket-photos');

-- Realtime: the app listens for changes on tickets.
alter publication supabase_realtime add table public.tickets;
