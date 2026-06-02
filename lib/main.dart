import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_snackbar.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'features/todo_kanban/presentation/pages/main_kanban_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://uqhydfuztyouyvxfyazy.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVxaHlkZnV6dHlvdXl2eGZ5YXp5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4NTYzNTYsImV4cCI6MjA5NTQzMjM1Nn0.ZUjwYOM0yDktDNxWBmtpt7NVFy8dO9t-XUR5tHNWMqo',
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authControllerProvider);

    return MaterialApp(
      title: 'Kanban',
      scaffoldMessengerKey: appScaffoldMessengerKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          surface: Colors.white,
          surfaceContainerLowest: const Color(0xFFF8FAFC),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
        ),
      ),
      home: currentUser == null ? const AuthPage() : const MainKanbanScreen(),
    );
  }
}
