import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'features/todo_kanban/presentation/controllers/task_controller.dart';
import 'features/todo_kanban/presentation/widgets/kanban_column.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://uqhydfuztyouyvxfyazy.supabase.co', // 🔍 這裡保持你原本的 URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVxaHlkZnV6dHlvdXl2eGZ5YXp5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4NTYzNTYsImV4cCI6MjA5NTQzMjM1Nn0.ZUjwYOM0yDktDNxWBmtpt7NVFy8dO9t-XUR5tHNWMqo', // 🔍 這裡保持你原本的 KEY
  );

  runApp(const ProviderScope(
    child: MyApp(),
  ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 🔍 監聽登入狀態
    final currentUser = ref.watch(authControllerProvider);

    return MaterialApp(
      title: 'Kanban Flux',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      // 2. 💡 狀態路由守門員
      // 如果 currentUser 是 null -> 乖乖去 AuthPage 登入
      // 如果 currentUser 有資料 -> 解鎖進入主要的明細看板！
      home: currentUser == null
          ? const AuthPage()
          : const MainKanbanScreen(),
    );
  }
}

/// 💡 我們把原本主看板的 Scaffold 抽出來獨立成一個 Widget，方便 main 進行切換
class MainKanbanScreen extends ConsumerWidget {
  const MainKanbanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kanban Flux (Trello 模式)'),
        backgroundColor: Colors.indigo[50],
        actions: [
          // 💡 增加一個登出按鈕
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('出錯了: $err')),
        data: (tasks) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KanbanColumn(title: '待辦事項', status: 'todo', tasks: tasks),
                KanbanColumn(title: '進行中', status: 'in_progress', tasks: tasks),
                KanbanColumn(title: '已完成', status: 'done', tasks: tasks),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await ref.read(taskControllerProvider.notifier).addTask(
            '專屬任務 ${DateTime.now().second}',
            '這條任務只屬於目前登入的你',
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}