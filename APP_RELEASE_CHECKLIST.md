# Kanban Flux App Release Checklist

## Local Run With Supabase Config

The app reads Supabase settings from Dart defines, with current project values as fallbacks.

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=PASSWORD_RESET_REDIRECT_URL=https://your-app-reset-url
```

For web server preview:

```bash
flutter run -d web-server \
  --web-hostname 127.0.0.1 \
  --web-port 5777 \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=PASSWORD_RESET_REDIRECT_URL=http://127.0.0.1:5777
```

## Production Build

Android app bundle:

```bash
flutter build appbundle \
  --dart-define=SUPABASE_URL=https://your-production-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-production-anon-key \
  --dart-define=PASSWORD_RESET_REDIRECT_URL=https://your-app-reset-url
```

Web:

```bash
flutter build web \
  --dart-define=SUPABASE_URL=https://your-production-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-production-anon-key \
  --dart-define=PASSWORD_RESET_REDIRECT_URL=https://your-production-site.com
```

## Before Store Submission

- Back up the production Supabase project.
- Run `supabase/migrations/001_init_tasks.sql` in the production Supabase SQL Editor.
- Run `supabase/migrations/002_enable_tasks_realtime.sql` in the production Supabase SQL Editor.
- Confirm Supabase RLS is enabled on `public.tasks`.
- Confirm each RLS policy only allows authenticated users to access rows where `auth.uid() = user_id`.
- Add the password reset redirect URL to Supabase Auth URL configuration.
- Add app icon and splash screen.
- Prepare privacy policy, screenshots, and reviewer test account.
