import 'package:flutter/foundation.dart';

enum CastState { notConnected, connecting, connected }

class CastProvider extends ChangeNotifier {
  CastState _castState = CastState.notConnected;
  String? _connectedDeviceName;
  String? _currentCastUrl;

  CastState get castState => _castState;
  String? get connectedDeviceName => _connectedDeviceName;
  bool get isConnected => _castState == CastState.connected;
  String? get currentCastUrl => _currentCastUrl;

  Future<void> init() async {
    // Cast framework initialisation handled natively via CastOptionsProvider.kt
    // Flutter-side we just track state
  }

  Future<void> connect(String deviceName) async {
    _castState = CastState.connecting;
    notifyListeners();

    // Simulated connection — in a full implementation, use flutter_cast_framework
    await Future.delayed(const Duration(seconds: 2));
    _castState = CastState.connected;
    _connectedDeviceName = deviceName;
    notifyListeners();
  }

  Future<void> disconnect() async {
    _castState = CastState.notConnected;
    _connectedDeviceName = null;
    _currentCastUrl = null;
    notifyListeners();
  }

  Future<void> castChannel(String streamUrl, String channelName) async {
    if (_castState != CastState.connected) return;
    _currentCastUrl = streamUrl;
    notifyListeners();
    // Trigger native Cast session via platform channel
  }

  Future<void> stopCasting() async {
    _currentCastUrl = null;
    notifyListeners();
  }
}
