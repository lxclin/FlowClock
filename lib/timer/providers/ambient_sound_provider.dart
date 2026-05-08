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
        return 'assets/audio/white_noise.wav';
      case AmbientSound.rain:
        return 'assets/audio/rain.wav';
      case AmbientSound.cafe:
        return 'assets/audio/cafe.wav';
      case AmbientSound.forest:
        return 'assets/audio/forest.wav';
      case AmbientSound.none:
        return '';
    }
  }
}

final ambientSoundProvider =
    StateNotifierProvider<AmbientSoundNotifier, AmbientSound>((ref) {
  return AmbientSoundNotifier();
});

class AmbientSoundNotifier extends StateNotifier<AmbientSound> {
  final AudioPlayer _player = AudioPlayer();
  double _volume = 0.3;

  AmbientSoundNotifier() : super(AmbientSound.none);

  Future<void> setSound(AmbientSound sound) async {
    await _player.stop();
    state = sound;

    if (sound != AmbientSound.none) {
      await _player.setSource(AssetSource(sound.assetPath));
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(_volume);
      await _player.resume();
    }
  }

  Future<void> setVolume(double volume) async {
    _volume = volume;
    await _player.setVolume(volume);
  }

  Future<void> stop() async {
    await _player.stop();
    state = AmbientSound.none;
  }

  @override
  Future<void> dispose() async {
    await _player.dispose();
    super.dispose();
  }
}
