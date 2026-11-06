import 'package:flutter/widgets.dart';

typedef BiometricAuthenticator = Future<bool> Function();

/// Protects an established rally session after the app has been backgrounded.
///
/// The controller obscures the UI immediately to protect the app-switcher
/// snapshot, then requires biometrics only when the configured grace period
/// has elapsed.
class SessionLockController extends ChangeNotifier with WidgetsBindingObserver {
  SessionLockController({
    required BiometricAuthenticator authenticate,
    this.gracePeriod = const Duration(minutes: 1),
    DateTime Function()? now,
  }) : _authenticate = authenticate,
       _now = now ?? DateTime.now {
    WidgetsBinding.instance.addObserver(this);
  }

  final BiometricAuthenticator _authenticate;
  final DateTime Function() _now;
  final Duration gracePeriod;

  DateTime? _backgroundedAt;
  bool _sessionActive = false;
  bool _isLocked = false;
  bool _isObscured = false;
  bool _isUnlocking = false;

  bool get isLocked => _isLocked;
  bool get isObscured => _isObscured;
  bool get isUnlocking => _isUnlocking;

  /// Starts background protection after the user has selected an organization.
  void activate() {
    _sessionActive = true;
    _backgroundedAt = null;
    _isLocked = false;
    _isObscured = false;
    notifyListeners();
  }

  Future<void> unlock() => _requestUnlock();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_sessionActive) return;

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _backgroundedAt ??= _now();
        if (!_isObscured) {
          _isObscured = true;
          notifyListeners();
        }
        return;
      case AppLifecycleState.resumed:
        _handleResumed();
        return;
      case AppLifecycleState.detached:
        return;
    }
  }

  void _handleResumed() {
    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;

    // A biometric prompt temporarily makes iOS inactive. Keep the existing
    // lock visible until that prompt completes instead of treating it as a
    // short background transition.
    if (_isLocked || _isUnlocking || backgroundedAt == null) return;

    if (_now().difference(backgroundedAt) >= gracePeriod) {
      _isLocked = true;
      _isObscured = true;
      notifyListeners();
      _requestUnlock();
      return;
    }

    _isObscured = false;
    notifyListeners();
  }

  Future<void> _requestUnlock() async {
    if (!_sessionActive || !_isLocked || _isUnlocking) return;

    _isUnlocking = true;
    notifyListeners();
    try {
      final unlocked = await _authenticate();
      if (unlocked && _sessionActive) {
        _isLocked = false;
        _isObscured = false;
      }
    } finally {
      _isUnlocking = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
