import 'package:audioplayers/audioplayers.dart';
import 'package:rally_lib/rally_lib.dart';

/// Plays an ongoing audible reminder while the odometer is in Park or Reverse.
///
/// The source files include intentional silence between tones, so looping them
/// produces a periodic reminder rather than continuous sound.
class DirectionAlertService {
  final AudioPlayer _player = AudioPlayer();
  OdometerDirection? _direction;
  int _operation = 0;

  Future<void> setDirection(OdometerDirection direction) async {
    if (_direction == direction) return;

    _direction = direction;
    final operation = ++_operation;
    await _player.stop();
    if (operation != _operation) return;

    final asset = switch (direction) {
      OdometerDirection.park => 'sounds/park_chime.wav',
      OdometerDirection.reverse => 'sounds/reverse_beep.wav',
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
