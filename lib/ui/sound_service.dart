import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Service for playing game sound effects.
///
/// Manages audio players for dice/shell rolling sounds, result reveals,
/// and bonus turn celebrations. Sounds are loaded from assets/sounds/.
class SoundService {
  static final SoundService _instance = SoundService._internal();

  /// Singleton instance.
  factory SoundService() => _instance;

  SoundService._internal();

  final AudioPlayer _effectPlayer = AudioPlayer();

  bool _initialized = false;

  /// Whether sound effects are enabled.
  bool soundEnabled = true;

  /// Initialize the sound service.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _effectPlayer.setVolume(0.5);
    await _effectPlayer.setReleaseMode(ReleaseMode.stop);
  }

  /// Play the dice rolling sound.
  Future<void> playDiceRoll() async {
    await _playSound('sounds/dice_roll.wav');
  }

  /// Play the shell throwing sound.
  Future<void> playShellThrow() async {
    await _playSound('sounds/shell_throw.wav');
  }

  /// Play the result reveal sound.
  Future<void> playResultReveal() async {
    await _playSound('sounds/result_reveal.wav');
  }

  /// Play the bonus turn sound.
  Future<void> playBonusTurn() async {
    await _playSound('sounds/bonus_turn.wav');
  }

  Future<void> _playSound(String assetPath) async {
    if (!soundEnabled) return;
    try {
      await _effectPlayer.stop();
      await _effectPlayer.play(AssetSource(assetPath));
    } catch (e) {
      // Silently ignore audio errors (e.g., in test environments)
      debugPrint('SoundService: Could not play $assetPath: $e');
    }
  }

  /// Dispose of audio resources.
  void dispose() {
    _effectPlayer.dispose();
  }
}
