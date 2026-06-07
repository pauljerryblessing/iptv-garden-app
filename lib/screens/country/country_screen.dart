import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/channel_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/channel_list_tile.dart';
import '../../models/channel.dart';

class CountryScreen extends StatefulWidget {
  const CountryScreen({super.key});

  @override
  State<CountryScreen> createState() => _CountryScreenState();
}

class _CountryScreenState extends State<CountryScreen> {
  String? _selectedCountry;
  List<Channel> _countryChannels = [];
  bool _loading = false;
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredCountries = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries(String query, List<String> all) {
    setState(() {
      _filteredCountries = query.isEmpty
          ? all
          : all
              .where((c) => c.toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }

  Future<void> _selectCountry(String country) async {
    setState(() {
      _selectedCountry = country;
      _loading = true;
      _countryChannels = [];
    });

    final provider = context.read<ChannelProvider>();
    final channels = provider.allChannels
        .where((c) =>
            c.country?.toLowerCase() == country.toLowerCase())
        .toList();

    setState(() {
      _countryChannels = channels;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.bgPrimary,
        title: Text(
            _selectedCountry != null ? _selectedCountry! : 'Browse by Country'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _selectedCountry != null
              ? () => setState(() {
                    _selectedCountry = null;
                    _countryChannels = [];
                  })
              : () => Navigator.pop(context),
        ),
      ),
      body: _selectedCountry != null
          ? _buildChannelList()
          : _buildCountryList(),
    );
  }

  Widget _buildCountryList() {
    return Consumer<ChannelProvider>(
      builder: (context, provider, _) {
        final countries = provider.availableCountries;
        if (_filteredCountries.isEmpty && _searchController.text.isEmpty) {
          _filteredCountries = countries;
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (q) => _filterCountries(q, countries),
                decoration: InputDecoration(
                  hintText: 'Search country...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            _filterCountries('', countries);
                          },
                        )
                      : null,
                ),
              ),
            ),
            Expanded(
              child: countries.isEmpty
                  ? const Center(
                      child: Text('No country data available',
                          style: TextStyle(color: AppTheme.textMuted)))
                  : ListView.builder(
                      itemCount: _filteredCountries.length,
                      itemBuilder: (context, index) {
                        final country = _filteredCountries[index];
                        final count = provider.allChannels
                            .where((c) =>
                                c.country?.toLowerCase() ==
                                country.toLowerCase())
                            .length;
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.bgCard,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.flag_rounded,
                                color: AppTheme.textSecondary, size: 20),
                          ),
                          title: Text(country),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.bgCard,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                  color: AppTheme.textMuted, fontSize: 12),
                            ),
                          ),
                          onTap: () => _selectCountry(country),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChannelList() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.accent));
    }
    if (_countryChannels.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tv_off_rounded,
                size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text('No channels for $_selectedCountry',
                style: const TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _countryChannels.length,
      itemBuilder: (context, index) =>
          ChannelListTile(channel: _countryChannels[index]),
    );
  }
}
