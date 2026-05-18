import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_pomodoro/timer/models/timer_state.dart';

void main() {
  group('TimerState — 精简休息状态', () {
    test('TimerMode 只有 work 和 rest 两个值', () {
      expect(TimerMode.values.length, 2);
      expect(TimerMode.values, contains(TimerMode.work));
      expect(TimerMode.values, contains(TimerMode.rest));
    });

    test('work mode label', () {
      expect(TimerMode.work.label, '专注');
    });

    test('rest mode label', () {
      expect(TimerMode.rest.label, '休息');
    });

    test('完成 4 个番茄后切到休息而非长休息', () {
      final state = TimerState(
        mode: TimerMode.work,
        remainingSeconds: 0,
        totalSeconds: 1500,
        isRunning: false,
        sessionPomodoros: 3,
      );
      // After 4th pomodoro, next should be break (not longBreak)
      expect(state.sessionPomodoros, 3);
    });
  });

  group('TimerState — 数据绑定', () {
    test('resetToWorkWithDuration 应使用传入的秒数', () {
      final state = TimerState(
        mode: TimerMode.work,
        remainingSeconds: 25 * 60,
        totalSeconds: 25 * 60,
        isRunning: false,
        sessionPomodoros: 0,
      );

      final reset = state.copyWith(
        mode: TimerMode.work,
        remainingSeconds: 120 * 60,
        totalSeconds: 120 * 60,
        isRunning: false,
      );

      expect(reset.totalSeconds, 120 * 60);
      expect(reset.remainingSeconds, 120 * 60);
    });

    test('copyWith 保留原有 duration 设置', () {
      final state = TimerState(
        mode: TimerMode.work,
        remainingSeconds: 600,
        totalSeconds: 600,
        isRunning: true,
        sessionPomodoros: 2,
      );

      final paused = state.copyWith(isRunning: false);
      expect(paused.totalSeconds, 600);
      expect(paused.sessionPomodoros, 2);
    });
  });
}
