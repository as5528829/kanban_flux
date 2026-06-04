# Supabase Setup

Run `supabase/migrations/001_init_tasks.sql` in the Supabase SQL Editor before testing or deploying Kanban Flux.

Then run `supabase/migrations/002_enable_tasks_realtime.sql` to enable secure private Broadcast updates across tabs and devices.

This migration creates or updates the `public.tasks` table with the fields used by the app:

- `priority`
- `due_date`
- `labels`
- `position`
- `created_at`
- `updated_at`

It also enables row-level security and adds policies so authenticated users can only select, insert, update, and delete their own tasks.

For an existing production project, take a database backup before running the migration. The migration is written to be repeatable, but production data changes should still be reviewed before execution.

The root-level `supabase_add_task_ui_fields.sql` and `supabase_add_task_position.sql` files are older incremental scripts. Prefer `supabase/migrations/001_init_tasks.sql` for new environments and release work.
