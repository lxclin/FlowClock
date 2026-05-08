import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pomodoro/app.dart';

void main() {
  testWidgets('App renders timer page', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PomodoroApp()));
    await tester.pump();
    await tester.pump();
    expect(find.text('计时'), findsWidgets);
  });
}
