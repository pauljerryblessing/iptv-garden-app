import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/channel.dart';

class RecentProvider extends ChangeNotifier {
  static const String _key = 'recent_channels';
  static const int _maxRecent = 20;
  List<Channel> _recent = [];

  List<Channel> get recentChannels => List.unmodifiable(_recent);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data != null) {
      try {
        final list = jsonDecode(data) as List;
        _recent = list.map((j) => Channel.fromJson(j as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> addRecent(Channel channel) async {
    _recent.removeWhere((c) => c.id == channel.id);
    final updated = channel.copyWith(
      lastWatched: DateTime.now(),
      watchCount: channel.watchCount + 1,
    );
    _recent.insert(0, updated);
    if (_recent.length > _maxRecent) {
      _recent = _recent.take(_maxRecent).toList();
    }
    await _save();
    notifyListeners();
  }

  Future<void> removeRecent(String channelId) async {
    _recent.removeWhere((c) => c.id == channelId);
    await _save();
    notifyListeners();
  }

  Future<void> clearRecent() async {
    _recent = [];
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_recent.map((c) => c.toJson()).toList());
    await prefs.setString(_key, data);
  }
}
