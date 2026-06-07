import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/channel.dart';
import '../../models/epg_program.dart';
import '../../providers/epg_provider.dart';
import '../../theme/app_theme.dart';
import 'program_detail_sheet.dart';

/// Shows the full schedule for a single channel.
/// Used inside the PlayerScreen bottom sheet.
class ChannelScheduleView extends StatelessWidget {
  final Channel channel;

  const ChannelScheduleView({super.key, required this.channel});

  @override
  Widget build(BuildContext context) {
    return Consumer<EpgProvider>(
      builder: (context, epg, _) {
        if (epg.isLoading) {
          return const SizedBox(
            height: 80,
            child: Center(
              child: CircularProgressIndicator(
                  color: AppTheme.accent, strokeWidth: 2),
            ),
          );
        }

        final schedule = epg.scheduleFor(channel.epgId ?? channel.id);
        if (schedule == null) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 16, color: AppTheme.textMuted),
                const SizedBox(width: 8),
                const Text(
                  'No schedule available for this channel',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ],
            ),
          );
        }

        final upcoming = schedule.upcoming;
        if (upcoming.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'No upcoming programs',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded,
                      size: 16, color: AppTheme.accent),
                  const SizedBox(width: 6),
                  const Text(
                    'Today\'s Schedule',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: upcoming.length,
                itemBuilder: (context, index) =>
                    _ScheduleCard(program: upcoming[index]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final EpgProgram program;

  const _ScheduleCard({required this.program});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.bgSecondary,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => ProgramDetailSheet(program: program),
      ),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: program.isLive
              ? AppTheme.accent.withOpacity(0.15)
              : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: program.isLive
                ? AppTheme.accent.withOpacity(0.5)
                : AppTheme.divider,
            width: program.isLive ? 1 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (program.isLive) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ] else
                  Text(
                    program.timeRange.split('–').first.trim(),
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 10),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              program.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: program.isLive
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: program.isLive
                    ? FontWeight.w700
                    : FontWeight.w500,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            if (program.isLive)
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: program.progress,
                  backgroundColor: AppTheme.divider,
                  color: AppTheme.accent,
                  minHeight: 3,
                ),
              )
            else
              Text(
                program.durationLabel,
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }
}
