import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/recent_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/channel_list_tile.dart';

class RecentScreen extends StatelessWidget {
  const RecentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.bgPrimary,
        title: const Text('Recently Watched'),
        automaticallyImplyLeading: false,
        actions: [
          Consumer<RecentProvider>(
            builder: (context, recent, _) => recent.recentChannels.isEmpty
                ? const SizedBox.shrink()
                : TextButton.icon(
                    onPressed: () => _showClearDialog(context, recent),
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 18, color: AppTheme.textMuted),
                    label: const Text('Clear',
                        style: TextStyle(color: AppTheme.textMuted)),
                  ),
          ),
        ],
      ),
      body: Consumer<RecentProvider>(
        builder: (context, recent, _) {
          if (recent.recentChannels.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_rounded,
                      size: 72,
                      color: AppTheme.textMuted.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  const Text('No recent history',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text(
                    'Channels you watch will appear here',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: recent.recentChannels.length,
            padding: const EdgeInsets.only(top: 4),
            itemBuilder: (context, index) => ChannelListTile(
              channel: recent.recentChannels[index],
              showTimestamp: true,
            ),
          );
        },
      ),
    );
  }

  void _showClearDialog(BuildContext context, RecentProvider recent) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgSecondary,
        title: const Text('Clear History'),
        content: const Text('Remove all recently watched channels?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textMuted))),
          TextButton(
            onPressed: () {
              recent.clearRecent();
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}
