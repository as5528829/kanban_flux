alter table tasks
add column if not exists priority text not null default 'medium';

alter table tasks
add column if not exists due_date date;

alter table tasks
add column if not exists labels text[] not null default '{}';

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'tasks_priority_check'
  ) then
    alter table tasks
    add constraint tasks_priority_check
    check (priority in ('low', 'medium', 'high'));
  end if;
end $$;
