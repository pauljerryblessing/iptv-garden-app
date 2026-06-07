import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/epg_provider.dart';
import '../../providers/channel_provider.dart';
import '../../models/channel.dart';
import '../../models/epg_program.dart';
import '../../screens/player/player_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/channel_logo.dart';
import '../../widgets/epg/epg_now_next_row.dart';
import '../../widgets/epg/program_detail_sheet.dart';

class EpgScreen extends StatefulWidget {
  const EpgScreen({super.key});

  @override
  State<EpgScreen> createState() => _EpgScreenState();
}

class _EpgScreenState extends State<EpgScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDay = DateTime.now();
  String _selectedCategory = 'All';

  static const _tabs = ['Now & Next', 'Full Guide', 'By Category'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final epg = context.read<EpgProvider>();
      if (!epg.hasData && !epg.isLoading) {
        epg.fetchEpg();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.bgPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.schedule_rounded, color: AppTheme.accent, size: 22),
            SizedBox(width: 8),
            Text('Program Guide'),
          ],
        ),
        actions: [
          Consumer<EpgProvider>(
            builder: (context, epg, _) => epg.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.accent),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () => context.read<EpgProvider>().refresh(),
                    tooltip: 'Refresh EPG',
                  ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accent,
          indicatorWeight: 2,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: Consumer2<EpgProvider, ChannelProvider>(
        builder: (context, epg, channels, _) {
          if (epg.isLoading && !epg.hasData) {
            return _buildLoading();
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _NowNextTab(channels: channels, epg: epg),
              _FullGuideTab(
                channels: channels,
                epg: epg,
                selectedDay: _selectedDay,
                onDayChanged: (d) => setState(() => _selectedDay = d),
              ),
              _ByCategoryTab(
                channels: channels,
                epg: epg,
                selectedCategory: _selectedCategory,
                onCategoryChanged: (c) =>
                    setState(() => _selectedCategory = c),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 3),
          ),
          SizedBox(height: 20),
          Text('Loading program guide...',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
          SizedBox(height: 8),
          Text('Fetching schedule data',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}

// ─── Now & Next Tab ──────────────────────────────────────────────────────────

class _NowNextTab extends StatelessWidget {
  final ChannelProvider channels;
  final EpgProvider epg;

  const _NowNextTab({required this.channels, required this.epg});

  @override
  Widget build(BuildContext context) {
    final channelList = channels.allChannels;

    if (!epg.hasData) {
      return _buildNoEpg(context);
    }

    // Build list: channels that have EPG data come first
    final withEpg = <Channel>[];
    final withoutEpg = <Channel>[];

    for (final ch in channelList) {
      if (epg.scheduleFor(ch.epgId ?? ch.id) != null) {
        withEpg.add(ch);
      } else {
        withoutEpg.add(ch);
      }
    }

    final all = [...withEpg, ...withoutEpg];
    if (all.isEmpty) return _buildNoEpg(context);

    return RefreshIndicator(
      color: AppTheme.accent,
      backgroundColor: AppTheme.bgCard,
      onRefresh: () => epg.refresh(),
      child: ListView.builder(
        itemCount: all.length,
        itemBuilder: (context, index) =>
            EpgNowNextRow(channel: all[index], epgProvider: epg),
      ),
    );
  }

  Widget _buildNoEpg(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tv_off_rounded,
                size: 64, color: AppTheme.textMuted.withOpacity(0.4)),
            const SizedBox(height: 16),
            const Text('No EPG Data',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Schedule data is unavailable right now.\nPull down to retry.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<EpgProvider>().fetchEpg(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Load Schedule'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Full Guide Tab ───────────────────────────────────────────────────────────

class _FullGuideTab extends StatelessWidget {
  final ChannelProvider channels;
  final EpgProvider epg;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDayChanged;

  const _FullGuideTab({
    required this.channels,
    required this.epg,
    required this.selectedDay,
    required this.onDayChanged,
  });

  @override
  Widget build(BuildContext context) {
    final channelList = channels.allChannels.take(100).toList();

    return Column(
      children: [
        _DaySelector(selected: selectedDay, onChanged: onDayChanged),
        Expanded(
          child: channelList.isEmpty
              ? const Center(
                  child: Text('No channels loaded',
                      style: TextStyle(color: AppTheme.textMuted)))
              : _buildTimelineGrid(context, channelList),
        ),
      ],
    );
  }

  Widget _buildTimelineGrid(BuildContext context, List<Channel> chList) {
    return CustomScrollView(
      slivers: [
        // Sticky time header
        SliverPersistentHeader(
          pinned: true,
          delegate: _TimelineHeaderDelegate(),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final channel = chList[index];
              final schedule = epg.scheduleFor(channel.epgId ?? channel.id);
              final programs =
                  schedule?.programsForDay(selectedDay) ?? [];

              return _ChannelTimelineRow(
                channel: channel,
                programs: programs,
                selectedDay: selectedDay,
              );
            },
            childCount: chList.length,
          ),
        ),
      ],
    );
  }
}

class _TimelineHeaderDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 36;
  @override
  double get maxExtent => 36;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Show hourly time markers
    return Container(
      color: AppTheme.bgSecondary,
      child: Row(
        children: [
          const SizedBox(width: 56), // channel logo space
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                children: List.generate(24, (h) {
                  return SizedBox(
                    width: 120,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '${h.toString().padLeft(2, '0')}:00',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate old) => false;
}

class _ChannelTimelineRow extends StatelessWidget {
  final Channel channel;
  final List<EpgProgram> programs;
  final DateTime selectedDay;

  const _ChannelTimelineRow({
    required this.channel,
    required this.programs,
    required this.selectedDay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        border:
            Border(bottom: BorderSide(color: AppTheme.divider.withOpacity(0.4))),
      ),
      child: Row(
        children: [
          // Channel logo
          Container(
            width: 56,
            alignment: Alignment.center,
            child: ChannelLogo(
                logoUrl: channel.logoUrl, size: 36, borderRadius: 4),
          ),
          // Programs timeline
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: programs.isEmpty
                  ? _noDataRow()
                  : Row(
                      children: programs
                          .map((p) => _ProgramBlock(program: p))
                          .toList(),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _noDataRow() {
    return Container(
      width: 2880, // 24h * 120px
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: const Text(
        'No schedule data available',
        style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
      ),
    );
  }
}

class _ProgramBlock extends StatelessWidget {
  final EpgProgram program;

  const _ProgramBlock({required this.program});

  @override
  Widget build(BuildContext context) {
    // 120px per hour, proportional width
    final width = (program.duration.inMinutes / 60) * 120.0;

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.bgSecondary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => ProgramDetailSheet(program: program),
      ),
      child: Container(
        width: width.clamp(60.0, double.infinity),
        height: 52,
        margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: program.isLive
              ? AppTheme.accent.withOpacity(0.25)
              : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: program.isLive
                ? AppTheme.accent.withOpacity(0.6)
                : AppTheme.divider,
            width: program.isLive ? 1 : 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (program.isLive)
              Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: const BoxDecoration(
                      color: AppTheme.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            Text(
              program.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: program.isLive
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: program.isLive
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
            Text(
              program.durationLabel,
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onChanged;

  const _DaySelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(
      7,
      (i) => today.add(Duration(days: i - 1)),
    );

    return SizedBox(
      height: 64,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = _isSameDay(day, selected);
          final isToday = _isSameDay(day, today);
          final label = isToday
              ? 'Today'
              : _dayLabel(day);

          return GestureDetector(
            onTap: () => onChanged(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.accent : AppTheme.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppTheme.accent : AppTheme.divider,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${day.day}/${day.month}',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white70
                          : AppTheme.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dayLabel(DateTime d) {
    const names = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
    ];
    return names[d.weekday - 1];
  }
}

// ─── By Category Tab ──────────────────────────────────────────────────────────

class _ByCategoryTab extends StatelessWidget {
  final ChannelProvider channels;
  final EpgProvider epg;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;

  const _ByCategoryTab({
    required this.channels,
    required this.epg,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Collect all current programs grouped by genre
    final Map<String, List<_ProgramWithChannel>> byCategory = {};

    for (final channel in channels.allChannels) {
      final schedule = epg.scheduleFor(channel.epgId ?? channel.id);
      final now = schedule?.nowPlaying;
      if (now == null) continue;

      final cat = now.category ?? channel.category;
      byCategory
          .putIfAbsent(cat, () => [])
          .add(_ProgramWithChannel(program: now, channel: channel));
    }

    final categories = ['All', ...byCategory.keys.toList()..sort()];

    List<_ProgramWithChannel> items;
    if (selectedCategory == 'All') {
      items = byCategory.values.expand((l) => l).toList();
    } else {
      items = byCategory[selectedCategory] ?? [];
    }

    return Column(
      children: [
        // Category chips
        SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: categories.length,
            itemBuilder: (context, i) {
              final cat = categories[i];
              final isSelected = cat == selectedCategory;
              return GestureDetector(
                onTap: () => onCategoryChanged(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.accent : AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isSelected
                            ? AppTheme.accent
                            : AppTheme.divider),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppTheme.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        if (items.isEmpty)
          const Expanded(
            child: Center(
              child: Text(
                'No live programs in this category right now',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _NowPlayingTile(
                    program: item.program, channel: item.channel);
              },
            ),
          ),
      ],
    );
  }
}

class _ProgramWithChannel {
  final EpgProgram program;
  final Channel channel;
  const _ProgramWithChannel({required this.program, required this.channel});
}

class _NowPlayingTile extends StatelessWidget {
  final EpgProgram program;
  final Channel channel;

  const _NowPlayingTile({required this.program, required this.channel});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlayerScreen(channel: channel)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
              bottom:
                  BorderSide(color: AppTheme.divider.withOpacity(0.4))),
        ),
        child: Row(
          children: [
            ChannelLogo(
                logoUrl: channel.logoUrl, size: 44, borderRadius: 6),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    program.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    channel.name,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: program.progress,
                      backgroundColor:
                          AppTheme.divider,
                      color: AppTheme.accent,
                      minHeight: 3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    program.timeRange,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: AppTheme.accent.withOpacity(0.4), width: 0.5),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
