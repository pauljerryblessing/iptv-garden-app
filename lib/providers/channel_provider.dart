import 'package:flutter/foundation.dart';
import '../models/channel.dart';
import '../services/iptv_service.dart';

enum LoadState { idle, loading, loaded, error }

class ChannelProvider extends ChangeNotifier {
  final IPTVService _service = IPTVService();

  List<Channel> _allChannels = [];
  List<Channel> _filteredChannels = [];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  String? _selectedCountry;
  LoadState _loadState = LoadState.idle;
  String? _errorMessage;
  bool _isRefreshing = false;

  List<Channel> get channels => _filteredChannels;
  List<Channel> get allChannels => _allChannels;
  String get selectedCategory => _selectedCategory;
  String? get selectedCountry => _selectedCountry;
  LoadState get loadState => _loadState;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _loadState == LoadState.loading;
  bool get isRefreshing => _isRefreshing;

  List<String> get availableCountries {
    final countries = _allChannels
        .where((c) => c.country != null && c.country!.isNotEmpty)
        .map((c) => c.country!)
        .toSet()
        .toList();
    countries.sort();
    return countries;
  }

  List<String> get availableCategories {
    final cats = _allChannels.map((c) => c.category).toSet().toList();
    cats.sort();
    return ['All', ...cats.where((c) => c != 'All')];
  }

  Future<void> loadChannels({bool forceRefresh = false}) async {
    if (_loadState == LoadState.loading) return;

    _loadState = LoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _allChannels = await _service.fetchChannels(forceRefresh: forceRefresh);
      _loadState = LoadState.loaded;
      _applyFilters();
    } catch (e) {
      _loadState = LoadState.error;
      _errorMessage = 'Failed to load channels. Please check your connection.';
    }

    notifyListeners();
  }

  Future<void> refresh() async {
    _isRefreshing = true;
    notifyListeners();
    await loadChannels(forceRefresh: true);
    _isRefreshing = false;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _selectedCountry = null;
    _applyFilters();
    notifyListeners();
  }

  void setCountry(String? country) {
    _selectedCountry = country;
    _applyFilters();
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query.trim().toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    var channels = List<Channel>.from(_allChannels);

    // Category filter
    if (_selectedCategory != 'All') {
      channels = channels
          .where((c) => c.category.toLowerCase() == _selectedCategory.toLowerCase())
          .toList();
    }

    // Country filter
    if (_selectedCountry != null) {
      channels = channels
          .where((c) =>
              c.country?.toLowerCase() == _selectedCountry!.toLowerCase())
          .toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      channels = channels
          .where((c) =>
              c.name.toLowerCase().contains(_searchQuery) ||
              c.category.toLowerCase().contains(_searchQuery) ||
              (c.country?.toLowerCase().contains(_searchQuery) ?? false))
          .toList();
    }

    _filteredChannels = channels;
  }

  List<Channel> searchChannels(String query) {
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase();
    return _allChannels
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.category.toLowerCase().contains(q) ||
            (c.country?.toLowerCase().contains(q) ?? false))
        .take(50)
        .toList();
  }

  Channel? getChannelById(String id) {
    try {
      return _allChannels.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
