import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pomodoro/todo/pages/create_task_sheet.dart';

void main() {
  Widget buildApp() {
    return const ProviderScope(
      child: MaterialApp(home: Scaffold(body: CreateTaskSheet())),
    );
  }

  group('CreateTaskSheet — Slider ↔ TextField 双向绑定', () {
    testWidgets('拖动 Slider → TextField 值同步', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget);

      // Get slider widget and directly call onChanged
      final slider = tester.widget<Slider>(sliderFinder);
      slider.onChanged?.call(60.0);
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      final minuteField = tester.widget<TextField>(textFields.at(1));
      final text = minuteField.controller?.text ?? '';
      expect(text, '60');
    });

    testWidgets('输入数字 → Slider 位置同步', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      final minuteField = tester.widget<TextField>(textFields.at(1));
      minuteField.controller?.text = '90';
      minuteField.onChanged?.call('90');
      await tester.pumpAndSettle();

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, 90.0);
    });
  });
}
