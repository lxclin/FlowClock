import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';

enum AmbientSound { none, whiteNoise, rain, cafe, forest }

extension AmbientSoundX on AmbientSound {
  String get label {
    switch (this) {
      case AmbientSound.none:
        return '无';
      case AmbientSound.whiteNoise:
        return '白噪音';
      case AmbientSound.rain:
        return '雨声';
      case AmbientSound.cafe:
        return '咖啡馆';
      case AmbientSound.forest:
        return '森林';
    }
  }

  String get icon {
    switch (this) {
      case AmbientSound.none:
        return '🔇';
      case AmbientSound.whiteNoise:
        return '🌬️';
      case AmbientSound.rain:
        return '🌧️';
      case AmbientSound.cafe:
        return '☕';
      case AmbientSound.forest:
        return '🌲';
    }
  }

  String get assetPath {
    switch (this) {
      case AmbientSound.whiteNoise:
        return 'bgm/white_noise.mp3';
      case AmbientSound.rain:
        return 'bgm/rain.mp3';
      case AmbientSound.cafe:
        return 'bgm/cafe.mp3';
      case AmbientSound.forest:
        return 'bgm/forest.mp3';
      case AmbientSound.none:
        return '';
    }
  }
}

final ambientSoundProvider =
    StateNotifierProvider<AmbientSoundNotifier, AmbientSound>((ref) {
  return AmbientSoundNotifier();
});

final ambientVolumeProvider = StateProvider<double>((ref) => 0.3);

class AmbientSoundNotifier extends StateNotifier<AmbientSound> {
  final AudioPlayer _player = AudioPlayer();
  double _volume = 0.3;

  AmbientSoundNotifier() : super(AmbientSound.none) {
    _initPlayer();
  }

  void _initPlayer() {
    _player.onPlayerStateChanged.listen((state) {
      debugPrint('[AmbientSound] playerState: $state');
    });

    _player.onPlayerComplete.listen((_) {
      debugPrint('[AmbientSound] onPlayerComplete — should be looping');
    });

    _player.onLog.listen((msg) {
      debugPrint('[AmbientSound] log: $msg');
    });
  }

  Future<void> setSound(AmbientSound sound) async {
    try {
      await _player.stop();
      state = sound;

      if (sound == AmbientSound.none) return;

      debugPrint('[AmbientSound] loading: ${sound.assetPath}');

      final bytes = await rootBundle.load(sound.assetPath);
      final data = bytes.buffer.asUint8List();
      debugPrint('[AmbientSound] loaded ${data.length} bytes');

      final isMp3 = sound.assetPath.endsWith('.mp3');
      final source = BytesSource(data,
          mimeType: isMp3 ? 'audio/mpeg' : 'audio/wav');
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(_volume);
      await _player.play(source);

      debugPrint('[AmbientSound] playing: ${sound.label}');
    } catch (e, stack) {
      debugPrint('[AmbientSound] ERROR: $e');
      debugPrint('[AmbientSound] stack: $stack');
    }
  }

  Future<void> setVolume(double volume) async {
    _volume = volume;
    await _player.setVolume(volume);
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('[AmbientSound] stop error: $e');
    }
    state = AmbientSound.none;
  }

  @override
  Future<void> dispose() async {
    await _player.dispose();
    super.dispose();
  }
}
