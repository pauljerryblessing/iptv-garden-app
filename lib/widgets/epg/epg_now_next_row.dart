import 'package:flutter/material.dart';
import '../../models/channel.dart';
import '../../models/epg_program.dart';
import '../../providers/epg_provider.dart';
import '../../screens/player/player_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/channel_logo.dart';
import 'program_detail_sheet.dart';

class EpgNowNextRow extends StatelessWidget {
  final Channel channel;
  final EpgProvider epgProvider;

  const EpgNowNextRow({
    super.key,
    required this.channel,
    required this.epgProvider,
  });

  @override
  Widget build(BuildContext context) {
    final epgId = channel.epgId ?? channel.id;
    final now = epgProvider.nowPlaying(epgId);
    final next = epgProvider.nextUp(epgId);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.divider.withOpacity(0.4)),
        ),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PlayerScreen(channel: channel)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Channel logo + name
              Column(
                children: [
                  ChannelLogo(
                      logoUrl: channel.logoUrl, size: 44, borderRadius: 6),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 52,
                    child: Text(
                      channel.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 9,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // EPG content
              Expanded(
                child: now == null
                    ? _buildNoData()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _NowBlock(program: now),
                          if (next != null) ...[
                            const SizedBox(height: 6),
                            _NextBlock(program: next),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoData() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 14, color: AppTheme.textMuted),
          const SizedBox(width: 6),
          const Text(
            'No schedule available',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const Spacer(),
          const Icon(Icons.play_circle_outline_rounded,
              size: 16, color: AppTheme.textMuted),
        ],
      ),
    );
  }
}

class _NowBlock extends StatelessWidget {
  final EpgProgram program;
  const _NowBlock({required this.program});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // LIVE dot
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                'NOW',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                program.timeRange,
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 10),
              ),
              const Spacer(),
              Text(
                program.durationLabel,
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            program.title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (program.description != null) ...[
            const SizedBox(height: 2),
            Text(
              program.description!,
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 6),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              FractionallySizedBox(
                widthFactor: program.progress,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NextBlock extends StatelessWidget {
  final EpgProgram program;
  const _NextBlock({required this.program});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'NEXT',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            program.title,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          program.timeRange,
          style:
              const TextStyle(color: AppTheme.textMuted, fontSize: 10),
        ),
      ],
    );
  }
}
