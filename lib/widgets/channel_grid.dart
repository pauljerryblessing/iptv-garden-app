import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/channel_provider.dart';
import '../providers/recent_provider.dart';
import '../theme/app_theme.dart';
import 'channel_card.dart';
import 'channel_list_tile.dart';
import 'section_header.dart';

class ChannelGrid extends StatelessWidget {
  const ChannelGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ChannelProvider, RecentProvider>(
      builder: (context, channels, recent, _) {
        final isPortrait =
            MediaQuery.of(context).orientation == Orientation.portrait;
        final screenWidth = MediaQuery.of(context).size.width;

        // How many card columns in grid mode
        final crossAxisCount = screenWidth < 600
            ? 2
            : screenWidth < 900
                ? 3
                : 4;

        // Split channels into sections for a Netflix-style layout
        final allChannels = channels.channels;
        if (allChannels.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Continue Watching (recent)
            if (recent.recentChannels.isNotEmpty && channels.selectedCategory == 'All') ...[
              const SectionHeader(
                  title: 'Continue Watching', icon: Icons.history_rounded),
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: recent.recentChannels.take(10).length,
                  itemBuilder: (context, index) => ChannelCard(
                    channel: recent.recentChannels[index],
                    width: 130,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Featured horizontal rows per category
            if (channels.selectedCategory == 'All') ...[
              ..._buildCategoryRows(context, allChannels),
            ] else ...[
              SectionHeader(
                title: '${channels.selectedCategory} Channels',
                icon: Icons.live_tv_rounded,
                count: allChannels.length,
              ),
              // Grid view for category
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.75,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: allChannels.length,
                  itemBuilder: (context, index) =>
                      ChannelCard(channel: allChannels[index], width: double.infinity),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        );
      },
    );
  }

  List<Widget> _buildCategoryRows(BuildContext context, List channels) {
    const categories = [
      'News', 'Sports', 'Movies', 'Entertainment',
      'Kids', 'Music', 'Documentary', 'International',
    ];
    final widgets = <Widget>[];

    for (final cat in categories) {
      final catChannels = channels
          .where((c) => c.category == cat)
          .take(15)
          .toList();
      if (catChannels.isEmpty) continue;

      widgets.add(SectionHeader(
        title: cat,
        icon: _categoryIcon(cat),
        count: catChannels.length,
        color: AppTheme.categoryColors[cat] ?? AppTheme.textSecondary,
      ));
      widgets.add(SizedBox(
        height: 160,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: catChannels.length,
          itemBuilder: (context, index) =>
              ChannelCard(channel: catChannels[index]),
        ),
      ));
      widgets.add(const SizedBox(height: 20));
    }

    return widgets;
  }

  IconData _categoryIcon(String cat) {
    return {
      'News': Icons.newspaper_rounded,
      'Sports': Icons.sports_soccer_rounded,
      'Movies': Icons.movie_rounded,
      'Entertainment': Icons.live_tv_rounded,
      'Kids': Icons.child_care_rounded,
      'Music': Icons.music_note_rounded,
      'Documentary': Icons.theaters_rounded,
      'International': Icons.language_rounded,
    }[cat] ?? Icons.tv_rounded;
  }
}
