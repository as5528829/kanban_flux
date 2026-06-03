-- Kanban Flux tasks schema and row-level security.
-- Run this in the Supabase SQL Editor for a new project, or to bring an
-- existing project up to the current app schema.

create extension if not exists pgcrypto;

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text not null default '',
  status text not null default 'todo',
  priority text not null default 'medium',
  due_date date,
  labels text[] not null default '{}',
  position integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.tasks
  add column if not exists user_id uuid references auth.users(id) on delete cascade,
  add column if not exists title text,
  add column if not exists description text not null default '',
  add column if not exists status text not null default 'todo',
  add column if not exists priority text not null default 'medium',
  add column if not exists due_date date,
  add column if not exists labels text[] not null default '{}',
  add column if not exists position integer not null default 0,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

update public.tasks
set
  title = coalesce(nullif(btrim(title), ''), 'Untitled task'),
  description = coalesce(description, ''),
  status = coalesce(status, 'todo'),
  priority = coalesce(priority, 'medium'),
  labels = coalesce(labels, '{}'),
  position = coalesce(position, 0),
  created_at = coalesce(created_at, now()),
  updated_at = coalesce(updated_at, now());

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'tasks'
      and column_name = 'title'
      and is_nullable = 'YES'
  ) then
    alter table public.tasks alter column title set not null;
  end if;
end $$;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'tasks'
      and column_name = 'user_id'
      and is_nullable = 'YES'
  ) then
    alter table public.tasks alter column user_id set not null;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'tasks_title_not_blank_check'
  ) then
    alter table public.tasks
      add constraint tasks_title_not_blank_check
      check (length(btrim(title)) > 0);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'tasks_status_check'
  ) then
    alter table public.tasks
      add constraint tasks_status_check
      check (status in ('todo', 'in_progress', 'done'));
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'tasks_priority_check'
  ) then
    alter table public.tasks
      add constraint tasks_priority_check
      check (priority in ('low', 'medium', 'high'));
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'tasks_position_nonnegative_check'
  ) then
    alter table public.tasks
      add constraint tasks_position_nonnegative_check
      check (position >= 0);
  end if;
end $$;

with ranked_tasks as (
  select
    id,
    row_number() over (
      partition by user_id, status
      order by position asc, created_at desc
    ) - 1 as new_position
  from public.tasks
)
update public.tasks
set position = ranked_tasks.new_position
from ranked_tasks
where public.tasks.id = ranked_tasks.id;

create index if not exists tasks_user_status_position_idx
  on public.tasks (user_id, status, position);

create index if not exists tasks_user_created_at_idx
  on public.tasks (user_id, created_at desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists tasks_set_updated_at on public.tasks;

create trigger tasks_set_updated_at
before update on public.tasks
for each row
execute function public.set_updated_at();

alter table public.tasks enable row level security;

drop policy if exists tasks_select_own on public.tasks;
drop policy if exists tasks_insert_own on public.tasks;
drop policy if exists tasks_update_own on public.tasks;
drop policy if exists tasks_delete_own on public.tasks;

create policy tasks_select_own
on public.tasks
for select
using (auth.uid() = user_id);

create policy tasks_insert_own
on public.tasks
for insert
with check (auth.uid() = user_id);

create policy tasks_update_own
on public.tasks
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy tasks_delete_own
on public.tasks
for delete
using (auth.uid() = user_id);
