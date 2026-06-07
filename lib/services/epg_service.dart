import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/epg_program.dart';
import 'xmltv_parser.dart';

class EpgService {
  static final EpgService _instance = EpgService._internal();
  factory EpgService() => _instance;
  EpgService._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 60),
    headers: {'User-Agent': 'IPTVGarden/1.0 Flutter'},
  ));

  static const String _cacheKey = 'epg_cache';
  static const String _cacheTimeKey = 'epg_cache_time';
  static const Duration _cacheExpiry = Duration(hours: 3);

  // Public XMLTV EPG sources
  static const List<String> _epgSources = [
    'https://iptv-org.github.io/epg/guides/us/tvtv.us.epg.xml',
    'https://iptv-org.github.io/epg/guides/uk/tvtv.uk.epg.xml',
    'https://raw.githubusercontent.com/iptv-org/epg/master/sites/tvguide.com/tvguide.com.epg.xml',
  ];

  Map<String, ChannelSchedule> _schedules = {};
  bool _isLoading = false;

  Map<String, ChannelSchedule> get schedules => Map.unmodifiable(_schedules);
  bool get isLoading => _isLoading;

  Future<Map<String, ChannelSchedule>> fetchEpg({
    String? epgUrl,
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheTime = prefs.getInt(_cacheTimeKey) ?? 0;
    final age = DateTime.now().millisecondsSinceEpoch - cacheTime;
    final isFresh = age < _cacheExpiry.inMilliseconds;

    if (!forceRefresh && isFresh && _schedules.isNotEmpty) {
      return _schedules;
    }

    // Check disk cache first
    if (!forceRefresh && isFresh) {
      final cached = prefs.getString(_cacheKey);
      if (cached != null) {
        try {
          final decoded = jsonDecode(cached) as Map<String, dynamic>;
          _schedules = decoded.map((id, data) {
            final programs = (data as List)
                .map((j) => EpgProgram.fromJson(j as Map<String, dynamic>))
                .toList();
            return MapEntry(id, ChannelSchedule(channelId: id, programs: programs));
          });
          if (_schedules.isNotEmpty) return _schedules;
        } catch (_) {}
      }
    }

    _isLoading = true;
    final url = epgUrl ?? _epgSources.first;

    try {
      final response = await _dio.get<String>(url);
      if (response.statusCode == 200 && response.data != null) {
        final parsed = XmltvParser.parse(response.data!);
        _schedules = parsed;
        await _persistCache(prefs, parsed);
      }
    } catch (_) {
      // Fallback: generate demo schedule if network fails
      _schedules = _generateDemoSchedule();
    }

    _isLoading = false;
    return _schedules;
  }

  ChannelSchedule? getScheduleForChannel(String channelId) {
    // Try exact match first
    if (_schedules.containsKey(channelId)) return _schedules[channelId];

    // Try partial match (tvg-id may differ slightly)
    final lower = channelId.toLowerCase();
    for (final entry in _schedules.entries) {
      if (entry.key.toLowerCase().contains(lower) ||
          lower.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return null;
  }

  EpgProgram? getNowPlaying(String channelId) =>
      getScheduleForChannel(channelId)?.nowPlaying;

  EpgProgram? getNextUp(String channelId) =>
      getScheduleForChannel(channelId)?.nextUp;

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimeKey);
    _schedules = {};
  }

  Future<void> _persistCache(
    SharedPreferences prefs,
    Map<String, ChannelSchedule> schedules,
  ) async {
    try {
      final data = schedules.map((id, schedule) => MapEntry(
            id,
            schedule.programs.map((p) => p.toJson()).toList(),
          ));
      await prefs.setString(_cacheKey, jsonEncode(data));
      await prefs.setInt(
          _cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  /// Generates realistic demo EPG data when the network is unavailable
  Map<String, ChannelSchedule> _generateDemoSchedule() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final demoPrograms = <String, List<Map<String, dynamic>>>{
      'news_demo': [
        {'title': 'Morning News', 'duration': 60, 'cat': 'News'},
        {'title': 'World Report', 'duration': 30, 'cat': 'News'},
        {'title': 'Market Update', 'duration': 30, 'cat': 'Business'},
        {'title': 'Afternoon News', 'duration': 60, 'cat': 'News'},
        {'title': 'Sports Desk', 'duration': 30, 'cat': 'Sports'},
        {'title': 'Evening News', 'duration': 60, 'cat': 'News'},
        {'title': 'Night Report', 'duration': 30, 'cat': 'News'},
        {'title': 'Late Edition', 'duration': 60, 'cat': 'News'},
      ],
      'sports_demo': [
        {'title': 'Football Highlights', 'duration': 90, 'cat': 'Sports'},
        {'title': 'Live Tennis', 'duration': 120, 'cat': 'Sports'},
        {'title': 'Basketball Recap', 'duration': 45, 'cat': 'Sports'},
        {'title': 'Sports Talk', 'duration': 60, 'cat': 'Sports'},
        {'title': 'Formula 1 Grand Prix', 'duration': 120, 'cat': 'Motorsport'},
        {'title': 'Boxing Tonight', 'duration': 90, 'cat': 'Sports'},
      ],
      'movies_demo': [
        {'title': 'The Great Adventure', 'duration': 120, 'cat': 'Action'},
        {'title': 'Comedy Hour', 'duration': 90, 'cat': 'Comedy'},
        {'title': 'Mystery at Midnight', 'duration': 110, 'cat': 'Thriller'},
        {'title': 'Sci-Fi Classics', 'duration': 100, 'cat': 'Science Fiction'},
        {'title': 'Drama Showcase', 'duration': 95, 'cat': 'Drama'},
      ],
    };

    final Map<String, ChannelSchedule> result = {};

    for (final entry in demoPrograms.entries) {
      final programs = <EpgProgram>[];
      var cursor = today;

      for (final prog in entry.value) {
        final dur = Duration(minutes: prog['duration'] as int);
        programs.add(EpgProgram(
          channelId: entry.key,
          title: prog['title'] as String,
          description: 'Watch ${prog['title']} on IPTV Garden.',
          startTime: cursor,
          endTime: cursor.add(dur),
          category: prog['cat'] as String?,
        ));
        cursor = cursor.add(dur);
      }

      result[entry.key] =
          ChannelSchedule(channelId: entry.key, programs: programs);
    }

    return result;
  }
}
