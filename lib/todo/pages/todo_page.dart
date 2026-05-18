import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../timer/providers/active_task_provider.dart';
import '../../timer/providers/timer_provider.dart';
import '../../timer/pages/timer_page.dart';
import '../../core/database/database_helper.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/task_tile.dart';
import 'create_task_sheet.dart';

class TodoPage extends ConsumerStatefulWidget {
  const TodoPage({super.key});

  @override
  ConsumerState<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends ConsumerState<TodoPage> {
  Map<int, int> _todayFocusCounts = {};
  Map<int, int> _todayFocusSeconds = {};

  @override
  void initState() {
    super.initState();
    _loadTodayStats();
  }

  Future<void> _loadTodayStats() async {
    final tasks = ref.read(taskProvider).active;
    final counts = <int, int>{};
    final seconds = <int, int>{};
    for (final t in tasks) {
      if (t.id != null) {
        counts[t.id!] = await DatabaseHelper.instance.getTodayFocusCountForTask(t.id!);
        seconds[t.id!] = await DatabaseHelper.instance.getTodayFocusSecondsForTask(t.id!);
      }
    }
    if (mounted) {
      setState(() {
        _todayFocusCounts = counts;
        _todayFocusSeconds = seconds;
      });
    }
  }

  void _showCreateSheet() {
    final state = ref.read(taskProvider);
    if (state.active.length >= 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('最多创建 9 个任务'), duration: Duration(seconds: 2)),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const CreateTaskSheet(),
    ).then((_) => _loadTodayStats());
  }

  void _startTask(Task task) {
    if (task.id != null) {
      ref.read(activeTaskIdProvider.notifier).state = task.id;
      ref.read(timerProvider.notifier).resetToWorkWithDuration(task.targetMinutes * 60);

      Navigator.of(context)
          .push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const TimerPage()))
          .then((_) => _loadTodayStats());
    }
  }

  void _showLongPressMenu(Task task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.trackColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(task.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: AppTheme.textPrimary),
              title: const Text('编辑'),
              onTap: () {
                Navigator.pop(context);
                _showEditSheet(task);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppTheme.workColor),
              title: const Text('删除', style: TextStyle(color: AppTheme.workColor)),
              onTap: () {
                Navigator.pop(context);
                ref.read(taskProvider.notifier).deleteTask(task.id!);
                _loadTodayStats();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showEditSheet(Task task) {
    final titleCtrl = TextEditingController(text: task.title);
    final minuteCtrl = TextEditingController(text: '${task.targetMinutes}');
    double sliderMinutes = task.targetMinutes.toDouble();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('编辑任务',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: '任务名称',
                  filled: true,
                  fillColor: AppTheme.bgCream,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              const Text('单次时长',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(trackHeight: 6, activeTrackColor: AppTheme.workColor, inactiveTrackColor: AppTheme.trackColor,
                          thumbColor: AppTheme.workColor, overlayColor: AppTheme.workColor.withValues(alpha: 0.15)),
                      child: Slider(
                          value: sliderMinutes.clamp(1, 180), min: 1, max: 180, divisions: 179,
                          onChanged: (v) => setSheetState(() {
                                sliderMinutes = v;
                                minuteCtrl.text = '${v.round()}';
                              })),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 78,
                    child: TextField(
                      controller: minuteCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      onChanged: (t) {
                        final v = int.tryParse(t);
                        if (v != null && v >= 1 && v <= 180) {
                          setSheetState(() => sliderMinutes = v.toDouble());
                        }
                      },
                      decoration: InputDecoration(
                        suffixText: '分钟', suffixStyle: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        filled: true, fillColor: AppTheme.bgCream,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8), isDense: true,
                      ),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(taskProvider.notifier).updateTask(
                          id: task.id!,
                          title: titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : null,
                          targetMinutes: sliderMinutes.round(),
                        );
                    Navigator.pop(ctx);
                    _loadTodayStats();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.workColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('保存', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskProvider);

    return Container(
      color: AppTheme.bgCream,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Row(
                children: [
                  const Text('任务',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  const SizedBox(width: 8),
                  if (state.active.isNotEmpty)
                    Text('${state.active.length}/9',
                        style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showCreateSheet,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.workColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.add, color: AppTheme.workColor, size: 22),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.active.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('📋', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 12),
                              const Text('还没有任务',
                                  style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                              const SizedBox(height: 4),
                              const Text('创建一个任务，让每一次专注都有目标',
                                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: _showCreateSheet,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('新建任务'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.workColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: state.active.length,
                          itemBuilder: (_, i) {
                            final task = state.active[i];
                            return TaskTile(
                              task: task,
                              isActive: task.id == ref.read(activeTaskIdProvider),
                              todayFocusCount: _todayFocusCounts[task.id] ?? 0,
                              todayFocusSeconds: _todayFocusSeconds[task.id] ?? 0,
                              onTap: () => _startTask(task),
                              onStart: () => _startTask(task),
                              onLongPress: () => _showLongPressMenu(task),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
