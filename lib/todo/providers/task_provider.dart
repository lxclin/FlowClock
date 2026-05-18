import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_helper.dart';
import '../models/task.dart';

final taskProvider = StateNotifierProvider<TaskNotifier, TaskListState>((ref) {
  return TaskNotifier();
});

class TaskListState {
  final List<Task> active;
  final List<Task> archived;
  final bool isLoading;

  const TaskListState({
    this.active = const [],
    this.archived = const [],
    this.isLoading = true,
  });

  TaskListState copyWith({
    List<Task>? active,
    List<Task>? archived,
    bool? isLoading,
  }) {
    return TaskListState(
      active: active ?? this.active,
      archived: archived ?? this.archived,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class TaskNotifier extends StateNotifier<TaskListState> {
  TaskNotifier() : super(const TaskListState()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    final maps = await DatabaseHelper.instance.getActiveTasks();
    final tasks = maps.map((m) => Task.fromMap(m)).toList();
    if (mounted) {
      state = TaskListState(active: tasks, isLoading: false);
    }
  }

  Future<Task> addTask({
    required String title,
    String? note,
    int targetMinutes = 25,
  }) async {
    final id = await DatabaseHelper.instance.insertTask(
      title: title,
      note: note,
      targetMinutes: targetMinutes,
    );
    final map = await DatabaseHelper.instance.getTaskById(id);
    final task = Task.fromMap(map!);
    state = state.copyWith(active: [...state.active, task]);
    return task;
  }

  Future<void> updateTask({
    required int id,
    String? title,
    int? targetMinutes,
    String? note,
  }) async {
    await DatabaseHelper.instance.updateTask(
      id: id,
      title: title,
      targetMinutes: targetMinutes,
      note: note,
    );
    await loadTasks();
  }

  Future<void> incrementPomodoro(int taskId) async {
    await DatabaseHelper.instance.incrementTaskPomodoro(taskId);
    await loadTasks();
  }

  Future<void> archiveTask(int id) async {
    await DatabaseHelper.instance.archiveTask(id, true);
    final task = state.active.firstWhere((t) => t.id == id);
    state = state.copyWith(
      active: state.active.where((t) => t.id != id).toList(),
      archived: [...state.archived, task.copyWith(isArchived: true)],
    );
  }

  Future<void> unarchiveTask(int id) async {
    await DatabaseHelper.instance.archiveTask(id, false);
    final task = state.archived.firstWhere((t) => t.id == id);
    state = state.copyWith(
      archived: state.archived.where((t) => t.id != id).toList(),
      active: [...state.active, task.copyWith(isArchived: false)],
    );
  }

  Future<void> deleteTask(int id) async {
    await DatabaseHelper.instance.deleteTask(id);
    state = state.copyWith(
      active: state.active.where((t) => t.id != id).toList(),
      archived: state.archived.where((t) => t.id != id).toList(),
    );
  }

  Future<void> reorder(List<int> orderedIds) async {
    await DatabaseHelper.instance.reorderTasks(orderedIds);
    final orderMap = {for (int i = 0; i < orderedIds.length; i++) orderedIds[i]: i};
    final sorted = List<Task>.from(state.active);
    sorted.sort((a, b) => (orderMap[a.id] ?? a.sortOrder).compareTo(orderMap[b.id] ?? b.sortOrder));
    state = state.copyWith(active: sorted);
  }
}
