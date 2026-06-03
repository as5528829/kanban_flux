class AppConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://uqhydfuztyouyvxfyazy.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVxaHlkZnV6dHlvdXl2eGZ5YXp5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4NTYzNTYsImV4cCI6MjA5NTQzMjM1Nn0.ZUjwYOM0yDktDNxWBmtpt7NVFy8dO9t-XUR5tHNWMqo',
  );

  static const passwordResetRedirectUrl = String.fromEnvironment(
    'PASSWORD_RESET_REDIRECT_URL',
  );
}
