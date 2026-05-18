import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pomodoro/todo/models/task.dart';
import 'package:flutter_pomodoro/todo/widgets/task_tile.dart';

void main() {
  group('TaskTile — 完成状态', () {
    Widget buildTile({required Task task, required int todayFocusCount, required int todayFocusSeconds}) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TaskTile(
              task: task,
              isActive: false,
              todayFocusCount: todayFocusCount,
              todayFocusSeconds: todayFocusSeconds,
              onTap: () {},
              onStart: () {},
              onLongPress: () {},
            ),
          ),
        ),
      );
    }

    testWidgets('已完成任务标题带删除线', (tester) async {
      final task = Task(
        title: '背单词',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildTile(
        task: task,
        todayFocusCount: 4,
        todayFocusSeconds: 3600,
      ));

      final titleFinder = find.textContaining('背单词');
      expect(titleFinder, findsOneWidget);

      final titleWidget = tester.widget<Text>(titleFinder.first);
      final style = titleWidget.style;
      expect(style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('未完成任务标题无删除线', (tester) async {
      final task = Task(
        title: '背单词',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildTile(
        task: task,
        todayFocusCount: 2,
        todayFocusSeconds: 1800,
      ));

      final titleFinder = find.textContaining('背单词');
      expect(titleFinder, findsOneWidget);

      final titleWidget = tester.widget<Text>(titleFinder.first);
      final style = titleWidget.style;
      expect(style?.decoration, TextDecoration.none);
    });
  });
}
