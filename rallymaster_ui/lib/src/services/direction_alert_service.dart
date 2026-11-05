import 'package:audioplayers/audioplayers.dart';
import 'package:rally_lib/rally_lib.dart';

/// Plays the shared Park and Reverse reminder sounds while either mode is
/// active. Sound assets are supplied by the RallyMaster UI package.
class DirectionAlertService {
  final AudioPlayer _player = AudioPlayer()
    ..audioCache = AudioCache(prefix: '');
  OdometerDirection? _direction;
  int _operation = 0;
  bool _audioContextConfigured = false;

  Future<void> setDirection(OdometerDirection direction) async {
    if (_direction == direction) return;

    _direction = direction;
    final operation = ++_operation;
    if (!_audioContextConfigured) {
      await _player.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(category: AVAudioSessionCategory.playback),
        ),
      );
      _audioContextConfigured = true;
    }
    if (operation != _operation) return;

    await _player.stop();
    if (operation != _operation) return;

    final asset = switch (direction) {
      OdometerDirection.park =>
        'packages/rallymaster_ui/assets/sounds/park_chime.wav',
      OdometerDirection.reverse =>
        'packages/rallymaster_ui/assets/sounds/reverse_beep.wav',
      OdometerDirection.forward => null,
    };
    if (asset == null) return;

    await _player.setReleaseMode(ReleaseMode.loop);
    if (operation != _operation) return;
    await _player.play(AssetSource(asset), volume: 0.75);
  }

  Future<void> dispose() async {
    ++_operation;
    await _player.dispose();
  }
}
