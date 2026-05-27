import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    final tasksAsync = ref.watch(taskControllerProvider);

    return MaterialApp(
      title: 'Kanban Flux',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Kanban Flux (Trello 模式)'),
          backgroundColor: Colors.indigo[50],
        ),
        backgroundColor: Colors.white,
        body: tasksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('出錯了: $err')),
          data: (tasks) {
            // 💡 使用 SingleChildScrollView 加上 scrollDirection: Axis.horizontal
            // 讓整個畫面可以像 Trello 一樣橫向滑動
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
              '新任務 ${DateTime.now().second}',
              '點擊卡片或拖曳來變更狀態',
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}