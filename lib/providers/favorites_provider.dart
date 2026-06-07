import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/channel.dart';

class FavoritesProvider extends ChangeNotifier {
  static const String _key = 'favorite_channels';
  List<Channel> _favorites = [];

  List<Channel> get favorites => List.unmodifiable(_favorites);
  bool isFavorite(String channelId) => _favorites.any((c) => c.id == channelId);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data != null) {
      try {
        final list = jsonDecode(data) as List;
        _favorites = list.map((j) => Channel.fromJson(j as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> addFavorite(Channel channel) async {
    if (!isFavorite(channel.id)) {
      _favorites.add(channel.copyWith(isFavorite: true));
      await _save();
      notifyListeners();
    }
  }

  Future<void> removeFavorite(String channelId) async {
    _favorites.removeWhere((c) => c.id == channelId);
    await _save();
    notifyListeners();
  }

  Future<void> toggleFavorite(Channel channel) async {
    if (isFavorite(channel.id)) {
      await removeFavorite(channel.id);
    } else {
      await addFavorite(channel);
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_favorites.map((c) => c.toJson()).toList());
    await prefs.setString(_key, data);
  }
}
