import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/iptv_service.dart';
import '../../theme/app_theme.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.bgPrimary,
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            children: [
              _sectionHeader('Stream'),
              _dropdownTile(
                context,
                icon: Icons.hd_rounded,
                title: 'Stream Quality',
                subtitle: 'Preferred quality for streams',
                value: settings.streamQuality,
                options: SettingsProvider.qualityOptions,
                onChanged: settings.setStreamQuality,
              ),
              _dropdownTile(
                context,
                icon: Icons.buffer,
                title: 'Buffer Size',
                subtitle: 'Larger buffer = smoother playback',
                value: settings.bufferSize,
                options: SettingsProvider.bufferOptions,
                onChanged: settings.setBufferSize,
              ),
              _switchTile(
                icon: Icons.play_arrow_rounded,
                title: 'Auto Play',
                subtitle: 'Start playback automatically',
                value: settings.autoPlay,
                onChanged: settings.setAutoPlay,
              ),
              _switchTile(
                icon: Icons.repeat_rounded,
                title: 'Continuous Play',
                subtitle: 'Auto-play next channel',
                value: settings.continuousPlay,
                onChanged: settings.setContinuousPlay,
              ),
              const Divider(color: AppTheme.divider, height: 1),
              _sectionHeader('Channels'),
              _switchTile(
                icon: Icons.refresh_rounded,
                title: 'Auto Refresh',
                subtitle: 'Automatically update channel list',
                value: settings.autoRefresh,
                onChanged: settings.setAutoRefresh,
              ),
              _dropdownTile(
                context,
                icon: Icons.timer_rounded,
                title: 'Refresh Interval',
                subtitle: 'How often to update channels',
                value: '${settings.refreshIntervalHours}h',
                options: ['3h', '6h', '12h', '24h'],
                onChanged: (val) {
                  final hours = int.tryParse(val.replaceAll('h', '')) ?? 6;
                  settings.setRefreshInterval(hours);
                },
              ),
              _switchTile(
                icon: Icons.format_list_numbered_rounded,
                title: 'Show Channel Numbers',
                subtitle: 'Display channel number in list',
                value: settings.showChannelNumbers,
                onChanged: settings.setShowChannelNumbers,
              ),
              const Divider(color: AppTheme.divider, height: 1),
              _sectionHeader('Cache & Data'),
              _actionTile(
                context,
                icon: Icons.cleaning_services_rounded,
                title: 'Clear Cache',
                subtitle: 'Remove cached channel data',
                iconColor: AppTheme.warning,
                onTap: () => _showClearCacheDialog(context),
              ),
              const Divider(color: AppTheme.divider, height: 1),
              _sectionHeader('Custom Playlist'),
              _actionTile(
                context,
                icon: Icons.add_link_rounded,
                title: 'Add Custom M3U URL',
                subtitle: 'Load channels from your own M3U playlist',
                iconColor: AppTheme.accent,
                onTap: () => _showCustomUrlDialog(context),
              ),
              const Divider(color: AppTheme.divider, height: 1),
              _sectionHeader('About'),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.info_outline_rounded,
                      color: AppTheme.textSecondary, size: 20),
                ),
                title: const Text('Version'),
                trailing: const Text('1.0.0',
                    style: TextStyle(color: AppTheme.textMuted)),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.live_tv_rounded,
                      color: AppTheme.accent, size: 20),
                ),
                title: const Text('Content Source'),
                subtitle: const Text('IPTV Garden / iptv-org',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.accent,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.textSecondary, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.accent,
    );
  }

  Widget _dropdownTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required List<String> options,
    required Function(String) onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.textSecondary, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.contains(value) ? value : options.first,
          dropdownColor: AppTheme.bgSecondary,
          style: const TextStyle(color: AppTheme.textPrimary),
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
      ),
    );
  }

  Widget _actionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor ?? AppTheme.textSecondary, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing:
          const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
      onTap: onTap,
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgSecondary,
        title: const Text('Clear Cache'),
        content:
            const Text('This will remove all cached channel data. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
            onPressed: () async {
              await IPTVService().clearCache();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared successfully')),
                );
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showCustomUrlDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgSecondary,
        title: const Text('Custom M3U Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your M3U playlist URL to load custom channels.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'https://example.com/playlist.m3u',
                prefixIcon: Icon(Icons.link_rounded),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Loading custom playlist...')),
                );
              }
            },
            child: const Text('Load'),
          ),
        ],
      ),
    );
  }
}
