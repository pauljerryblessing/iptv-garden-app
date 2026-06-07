import 'package:flutter/foundation.dart';
import '../models/epg_program.dart';
import '../services/epg_service.dart';

enum EpgLoadState { idle, loading, loaded, error }

class EpgProvider extends ChangeNotifier {
  final EpgService _service = EpgService();

  Map<String, ChannelSchedule> _schedules = {};
  EpgLoadState _state = EpgLoadState.idle;
  String? _errorMessage;
  DateTime? _lastFetched;

  Map<String, ChannelSchedule> get schedules => _schedules;
  EpgLoadState get state => _state;
  bool get isLoading => _state == EpgLoadState.loading;
  bool get hasData => _schedules.isNotEmpty;
  String? get errorMessage => _errorMessage;
  DateTime? get lastFetched => _lastFetched;

  Future<void> fetchEpg({String? customUrl, bool forceRefresh = false}) async {
    if (_state == EpgLoadState.loading) return;

    _state = EpgLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _schedules = await _service.fetchEpg(
        epgUrl: customUrl,
        forceRefresh: forceRefresh,
      );
      _state = EpgLoadState.loaded;
      _lastFetched = DateTime.now();
    } catch (e) {
      _state = EpgLoadState.error;
      _errorMessage = 'Could not load EPG data.';
    }

    notifyListeners();
  }

  ChannelSchedule? scheduleFor(String channelId) =>
      _service.getScheduleForChannel(channelId);

  EpgProgram? nowPlaying(String channelId) =>
      scheduleFor(channelId)?.nowPlaying;

  EpgProgram? nextUp(String channelId) =>
      scheduleFor(channelId)?.nextUp;

  List<EpgProgram> upcomingFor(String channelId) =>
      scheduleFor(channelId)?.upcoming ?? [];

  Future<void> refresh() => fetchEpg(forceRefresh: true);

  Future<void> clearCache() async {
    await _service.clearCache();
    _schedules = {};
    _state = EpgLoadState.idle;
    notifyListeners();
  }
}
