import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/favorites_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/channel_list_tile.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.bgPrimary,
        title: const Text('Favorites'),
        automaticallyImplyLeading: false,
        actions: [
          Consumer<FavoritesProvider>(
            builder: (context, favs, _) => favs.favorites.isEmpty
                ? const SizedBox.shrink()
                : TextButton.icon(
                    onPressed: () => _showClearDialog(context, favs),
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 18, color: AppTheme.textMuted),
                    label: const Text('Clear All',
                        style: TextStyle(color: AppTheme.textMuted)),
                  ),
          ),
        ],
      ),
      body: Consumer<FavoritesProvider>(
        builder: (context, favs, _) {
          if (favs.favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border_rounded,
                      size: 72,
                      color: AppTheme.textMuted.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  const Text('No favorites yet',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the heart icon on any channel to save it',
                    style: TextStyle(color: AppTheme.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: favs.favorites.length,
            padding: const EdgeInsets.only(top: 4),
            itemBuilder: (context, index) =>
                ChannelListTile(channel: favs.favorites[index]),
          );
        },
      ),
    );
  }

  void _showClearDialog(BuildContext context, FavoritesProvider favs) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgSecondary,
        title: const Text('Clear Favorites'),
        content: const Text('Remove all favorite channels?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textMuted))),
          TextButton(
            onPressed: () {
              for (final ch in List.from(favs.favorites)) {
                favs.removeFavorite(ch.id);
              }
              Navigator.pop(context);
            },
            child:
                const Text('Clear', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}
