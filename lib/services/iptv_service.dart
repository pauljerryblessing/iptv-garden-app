import 'dart:async';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/channel.dart';
import '../models/playlist_source.dart';
import 'm3u_parser.dart';

class IPTVService {
  static final IPTVService _instance = IPTVService._internal();
  factory IPTVService() => _instance;
  IPTVService._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    headers: {
      'User-Agent': 'IPTVGarden/1.0 Flutter',
    },
  ));

  static const String _cacheKey = 'cached_channels';
  static const String _cacheTimeKey = 'cache_timestamp';
  static const Duration _cacheExpiry = Duration(hours: 6);

  List<Channel> _cachedChannels = [];
  Timer? _refreshTimer;

  Future<List<Channel>> fetchChannels({
    String? customUrl,
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheTime = prefs.getInt(_cacheTimeKey) ?? 0;
    final isCacheValid = DateTime.now().millisecondsSinceEpoch - cacheTime < _cacheExpiry.inMilliseconds;

    if (!forceRefresh && isCacheValid && _cachedChannels.isNotEmpty) {
      return _cachedChannels;
    }

    // Check disk cache
    if (!forceRefresh && isCacheValid) {
      final cached = prefs.getStringList(_cacheKey);
      if (cached != null && cached.isNotEmpty) {
        try {
          _cachedChannels = cached.map((j) {
            final parts = j.split('|||');
            if (parts.length >= 5) {
              return Channel(
                id: parts[0],
                name: parts[1],
                streamUrl: parts[2],
                logoUrl: parts[3].isEmpty ? null : parts[3],
                category: parts[4],
                country: parts.length > 5 ? (parts[5].isEmpty ? null : parts[5]) : null,
              );
            }
            return null;
          }).whereType<Channel>().toList();

          if (_cachedChannels.isNotEmpty) return _cachedChannels;
        } catch (_) {}
      }
    }

    // Fetch fresh data
    final sources = customUrl != null
        ? [PlaylistSource(name: 'Custom', url: customUrl)]
        : [PlaylistSource.iptvGardenSources.first];

    final channels = <Channel>[];
    for (final source in sources) {
      try {
        final fetched = await _fetchFromSource(source.url);
        channels.addAll(fetched);
      } catch (e) {
        // Continue with next source
      }
    }

    if (channels.isNotEmpty) {
      _cachedChannels = channels;
      await _persistCache(prefs, channels);
    }

    return _cachedChannels.isNotEmpty ? _cachedChannels : channels;
  }

  Future<List<Channel>> fetchByCategory(String category) async {
    final url = _getCategoryUrl(category);
    try {
      return await _fetchFromSource(url);
    } catch (_) {
      return [];
    }
  }

  Future<List<Channel>> fetchByCountry(String countryCode) async {
    final url = 'https://iptv-org.github.io/iptv/countries/${countryCode.toLowerCase()}.m3u';
    try {
      return await _fetchFromSource(url);
    } catch (_) {
      return [];
    }
  }

  String _getCategoryUrl(String category) {
    final cat = category.toLowerCase();
    return 'https://iptv-org.github.io/iptv/categories/$cat.m3u';
  }

  Future<List<Channel>> _fetchFromSource(String url) async {
    final response = await _dio.get<String>(url);
    if (response.statusCode == 200 && response.data != null) {
      return M3UParser.parse(response.data!);
    }
    return [];
  }

  Future<bool> checkStreamAvailability(String url) async {
    try {
      final response = await _dio.head(url,
          options: Options(
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
            validateStatus: (status) => status != null && status < 500,
          ));
      return response.statusCode != null &&
          (response.statusCode! >= 200 && response.statusCode! < 400);
    } catch (_) {
      return false;
    }
  }

  void startAutoRefresh({Duration interval = const Duration(hours: 6)}) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(interval, (_) {
      fetchChannels(forceRefresh: true);
    });
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
  }

  Future<void> _persistCache(SharedPreferences prefs, List<Channel> channels) async {
    final simplified = channels.take(5000).map((c) =>
        '${c.id}|||${c.name}|||${c.streamUrl}|||${c.logoUrl ?? ''}|||${c.category}|||${c.country ?? ''}')
        .toList();
    await prefs.setStringList(_cacheKey, simplified);
    await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimeKey);
    _cachedChannels = [];
  }

  List<Channel> get cachedChannels => List.unmodifiable(_cachedChannels);
}
