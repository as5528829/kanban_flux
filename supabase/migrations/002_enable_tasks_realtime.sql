-- Securely broadcast task changes to the owning user's private topic.
alter table realtime.messages enable row level security;

drop policy if exists tasks_broadcasts_own on realtime.messages;

create policy tasks_broadcasts_own
on realtime.messages
for select
to authenticated
using (realtime.topic() = 'tasks:' || auth.uid()::text);

create or replace function public.broadcast_task_changes()
returns trigger
security definer
set search_path = ''
language plpgsql
as $$
begin
  perform realtime.broadcast_changes(
    'tasks:' || coalesce(new.user_id, old.user_id)::text,
    tg_op,
    tg_op,
    tg_table_name,
    tg_table_schema,
    new,
    old
  );
  return null;
end;
$$;

drop trigger if exists tasks_broadcast_changes on public.tasks;

create trigger tasks_broadcast_changes
after insert or update or delete on public.tasks
for each row
execute function public.broadcast_task_changes();
