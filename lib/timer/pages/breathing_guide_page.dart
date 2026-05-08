import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/timer_provider.dart';

class BreathingGuidePage extends ConsumerStatefulWidget {
  const BreathingGuidePage({super.key});

  @override
  ConsumerState<BreathingGuidePage> createState() => _BreathingGuidePageState();
}

class _BreathingGuidePageState extends ConsumerState<BreathingGuidePage> {
  int _phaseSeconds = 4;
  int _totalElapsed = 0;

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _totalElapsed++;
        _phaseSeconds = _totalElapsed % 8;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    final isInhaling = _phaseSeconds < 4;
    final phaseLabel = isInhaling ? '吸气' : '呼气';
    final phaseIcon = isInhaling ? '⬆️' : '⬇️';
    final size = isInhaling ? 180.0 : 120.0;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppTheme.breakBackground, Colors.white],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => _skipToWork(context, ref),
                      ),
                    ],
                  ),
                  const Spacer(flex: 1),
                  const Text(
                    '正念呼吸',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '跟随引导，让身心放松',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const Spacer(flex: 1),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 4000),
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.breakColor.withValues(alpha: isInhaling ? 0.3 : 0.12),
                      border: Border.all(
                        color: AppTheme.breakColor.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            phaseIcon,
                            style: const TextStyle(fontSize: 40),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            phaseLabel,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.breakColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(timerState.remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(timerState.remainingSeconds % 60).toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.textSecondary.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  TextButton(
                    onPressed: () => _skipToWork(context, ref),
                    child: const Text(
                      '感觉好多了，回到工作',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppTheme.breakColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _skipToWork(BuildContext context, WidgetRef ref) {
    ref.read(timerProvider.notifier).reset();
    Navigator.of(context, rootNavigator: true).pop();
  }
}
