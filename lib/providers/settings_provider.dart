import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _qualityKey = 'stream_quality';
  static const String _autoPlayKey = 'auto_play';
  static const String _autoRefreshKey = 'auto_refresh';
  static const String _refreshIntervalKey = 'refresh_interval_hours';
  static const String _bufferKey = 'buffer_size';

  String _streamQuality = 'Auto';
  bool _autoPlay = true;
  bool _autoRefresh = true;
  int _refreshIntervalHours = 6;
  String _bufferSize = 'Medium';
  bool _showChannelNumbers = true;
  bool _continuousPlay = false;

  String get streamQuality => _streamQuality;
  bool get autoPlay => _autoPlay;
  bool get autoRefresh => _autoRefresh;
  int get refreshIntervalHours => _refreshIntervalHours;
  String get bufferSize => _bufferSize;
  bool get showChannelNumbers => _showChannelNumbers;
  bool get continuousPlay => _continuousPlay;

  static const List<String> qualityOptions = ['Auto', 'HD', 'SD', 'Low'];
  static const List<String> bufferOptions = ['Small', 'Medium', 'Large'];

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _streamQuality = prefs.getString(_qualityKey) ?? 'Auto';
    _autoPlay = prefs.getBool(_autoPlayKey) ?? true;
    _autoRefresh = prefs.getBool(_autoRefreshKey) ?? true;
    _refreshIntervalHours = prefs.getInt(_refreshIntervalKey) ?? 6;
    _bufferSize = prefs.getString(_bufferKey) ?? 'Medium';
    notifyListeners();
  }

  Future<void> setStreamQuality(String quality) async {
    _streamQuality = quality;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_qualityKey, quality);
    notifyListeners();
  }

  Future<void> setAutoPlay(bool value) async {
    _autoPlay = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoPlayKey, value);
    notifyListeners();
  }

  Future<void> setAutoRefresh(bool value) async {
    _autoRefresh = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoRefreshKey, value);
    notifyListeners();
  }

  Future<void> setRefreshInterval(int hours) async {
    _refreshIntervalHours = hours;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_refreshIntervalKey, hours);
    notifyListeners();
  }

  Future<void> setBufferSize(String size) async {
    _bufferSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bufferKey, size);
    notifyListeners();
  }

  Future<void> setShowChannelNumbers(bool value) async {
    _showChannelNumbers = value;
    notifyListeners();
  }

  Future<void> setContinuousPlay(bool value) async {
    _continuousPlay = value;
    notifyListeners();
  }
}
