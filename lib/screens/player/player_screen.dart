import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../models/channel.dart';
import '../../models/epg_program.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/recent_provider.dart';
import '../../providers/cast_provider.dart';
import '../../providers/epg_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/channel_logo.dart';
import '../../widgets/epg/channel_schedule_view.dart';
import '../../widgets/epg/program_detail_sheet.dart';

class PlayerScreen extends StatefulWidget {
  final Channel channel;

  const PlayerScreen({super.key, required this.channel});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitializing = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isLandscape = false;
  bool _showEpgPanel = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
    _recordRecent();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _recordRecent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecentProvider>().addRecent(widget.channel);
    });
  }

  Future<void> _initPlayer() async {
    setState(() {
      _isInitializing = true;
      _hasError = false;
    });

    try {
      _videoController?.dispose();
      _chewieController?.dispose();

      final uri = Uri.parse(widget.channel.streamUrl);
      _videoController = VideoPlayerController.networkUrl(uri,
          httpHeaders: widget.channel.headers ?? {});

      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowPlaybackSpeedChanging: false,
        showControls: true,
        aspectRatio: _videoController!.value.aspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.accent,
          handleColor: AppTheme.accent,
          bufferedColor: AppTheme.accent.withOpacity(0.3),
          backgroundColor: Colors.white.withOpacity(0.2),
        ),
        placeholder: Container(color: AppTheme.bgPrimary),
        errorBuilder: (context, errorMessage) => _buildErrorWidget(errorMessage),
      );

      if (mounted) setState(() => _isInitializing = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _hasError = true;
          _errorMessage = 'Stream unavailable. Try again later.';
        });
      }
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLandscape ? _buildLandscape() : _buildPortrait(),
    );
  }

  // ── Portrait: stacked video + info panel ─────────────────────────────────

  Widget _buildPortrait() {
    return Column(
      children: [
        // Video area (16:9)
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              _buildVideoArea(),
              _buildTopBar(),
              Positioned(
                bottom: 12,
                right: 12,
                child: _buildCastButton(),
              ),
            ],
          ),
        ),

        // Info panel below video
        Expanded(
          child: Container(
            color: AppTheme.bgPrimary,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNowPlayingInfo(),
                  const Divider(color: AppTheme.divider, height: 1),
                  ChannelScheduleView(channel: widget.channel),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Landscape: full-screen video + sliding EPG panel ─────────────────────

  Widget _buildLandscape() {
    return Stack(
      children: [
        // Full-screen video
        Positioned.fill(child: _buildVideoArea()),

        // Top bar
        _buildTopBar(),

        // Cast + EPG toggle buttons
        Positioned(
          bottom: 80,
          right: 16,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'epg',
                backgroundColor: _showEpgPanel
                    ? AppTheme.accent
                    : AppTheme.bgSecondary.withOpacity(0.9),
                onPressed: () =>
                    setState(() => _showEpgPanel = !_showEpgPanel),
                child: const Icon(Icons.schedule_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(height: 8),
              _buildCastButton(),
            ],
          ),
        ),

        // Sliding EPG side panel (landscape only)
        if (_showEpgPanel)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 320,
            child: _EpgSidePanel(
              channel: widget.channel,
              onClose: () => setState(() => _showEpgPanel = false),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoArea() {
    if (_isInitializing) return _buildLoadingWidget();
    if (_hasError) return _buildErrorWidget(_errorMessage);
    if (_chewieController != null) return Chewie(controller: _chewieController!);
    return _buildLoadingWidget();
  }

  Widget _buildNowPlayingInfo() {
    return Consumer<EpgProvider>(
      builder: (context, epg, _) {
        final epgId = widget.channel.epgId ?? widget.channel.id;
        final now = epg.nowPlaying(epgId);
        final next = epg.nextUp(epgId);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Channel name row
              Row(
                children: [
                  ChannelLogo(
                    logoUrl: widget.channel.logoUrl,
                    size: 40,
                    borderRadius: 6,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.channel.name,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          widget.channel.category,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Consumer<FavoritesProvider>(
                    builder: (context, favs, _) {
                      final isFav = favs.isFavorite(widget.channel.id);
                      return IconButton(
                        icon: Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFav ? AppTheme.accent : AppTheme.textMuted,
                        ),
                        onPressed: () => favs.toggleFavorite(widget.channel),
                      );
                    },
                  ),
                ],
              ),

              // Now playing EPG
              if (now != null) ...[
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    backgroundColor: AppTheme.bgSecondary,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => ProgramDetailSheet(program: now),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.accent.withOpacity(0.3), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppTheme.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'NOW PLAYING',
                              style: TextStyle(
                                color: AppTheme.accent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              now.timeRange,
                              style: const TextStyle(
                                  color: AppTheme.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          now.title,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (now.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            now.description!,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: now.progress,
                            backgroundColor: AppTheme.divider,
                            color: AppTheme.accent,
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(now.progress * 100).toInt()}% complete',
                              style: const TextStyle(
                                  color: AppTheme.textMuted, fontSize: 11),
                            ),
                            Text(
                              now.durationLabel,
                              style: const TextStyle(
                                  color: AppTheme.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Up next
              if (next != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.skip_next_rounded,
                          size: 16, color: AppTheme.textMuted),
                      const SizedBox(width: 8),
                      const Text(
                        'UP NEXT  ',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          next.title,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        next.timeRange,
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],

              if (now == null && !epg.isLoading) ...[
                const SizedBox(height: 12),
                const Text(
                  'No schedule data available for this channel',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            ChannelLogo(
                logoUrl: widget.channel.logoUrl, size: 32, borderRadius: 4),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTopBarEpgInfo(),
            ),
            if (_isLandscape)
              Consumer<FavoritesProvider>(
                builder: (context, favs, _) {
                  final isFav = favs.isFavorite(widget.channel.id);
                  return IconButton(
                    icon: Icon(
                      isFav
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFav ? AppTheme.accent : Colors.white,
                    ),
                    onPressed: () => favs.toggleFavorite(widget.channel),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBarEpgInfo() {
    return Consumer<EpgProvider>(
      builder: (context, epg, _) {
        final now = epg.nowPlaying(widget.channel.epgId ?? widget.channel.id);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.channel.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              now != null ? now.title : widget.channel.category,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }

  Widget _buildCastButton() {
    return Consumer<CastProvider>(
      builder: (context, cast, _) => FloatingActionButton.small(
        heroTag: 'cast',
        backgroundColor: cast.isConnected
            ? AppTheme.accent
            : AppTheme.bgSecondary.withOpacity(0.9),
        onPressed: () => _showCastDialog(context, cast),
        child: const Icon(Icons.cast_rounded, color: Colors.white, size: 20),
      ),
    );
  }

  void _showCastDialog(BuildContext context, CastProvider cast) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CastSheet(channel: widget.channel, castProvider: cast),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ChannelLogo(
              logoUrl: widget.channel.logoUrl, size: 72, borderRadius: 12),
          const SizedBox(height: 20),
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
                color: AppTheme.accent, strokeWidth: 2.5),
          ),
          const SizedBox(height: 12),
          Text('Loading ${widget.channel.name}...',
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            const Text('Stream Unavailable',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initPlayer,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back',
                  style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── EPG Side Panel (landscape) ───────────────────────────────────────────────

class _EpgSidePanel extends StatelessWidget {
  final Channel channel;
  final VoidCallback onClose;

  const _EpgSidePanel({required this.channel, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgPrimary.withOpacity(0.95),
        border: const Border(
          left: BorderSide(color: AppTheme.divider, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded,
                      color: AppTheme.accent, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Programme Guide',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppTheme.textMuted, size: 20),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: AppTheme.divider, height: 1),
          Expanded(
            child: Consumer<EpgProvider>(
              builder: (context, epg, _) {
                final schedule =
                    epg.scheduleFor(channel.epgId ?? channel.id);
                final upcoming = schedule?.upcoming ?? [];

                if (epg.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.accent, strokeWidth: 2),
                  );
                }

                if (upcoming.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No schedule available\nfor this channel',
                        style: TextStyle(
                            color: AppTheme.textMuted, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: upcoming.length,
                  padding: const EdgeInsets.only(top: 4),
                  itemBuilder: (context, index) =>
                      _EpgPanelRow(program: upcoming[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EpgPanelRow extends StatelessWidget {
  final EpgProgram program;

  const _EpgPanelRow({required this.program});

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: program.isLive
              ? AppTheme.accent.withOpacity(0.1)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: AppTheme.divider.withOpacity(0.3)),
            left: program.isLive
                ? const BorderSide(color: AppTheme.accent, width: 3)
                : BorderSide.none,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 42,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _timeStr(program.startTime),
                    style: TextStyle(
                      color: program.isLive
                          ? AppTheme.accent
                          : AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    program.title,
                    style: TextStyle(
                      color: program.isLive
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: program.isLive
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (program.isLive) ...[
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: program.progress,
                        backgroundColor: AppTheme.divider,
                        color: AppTheme.accent,
                        minHeight: 3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeStr(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Cast Sheet ───────────────────────────────────────────────────────────────

class _CastSheet extends StatelessWidget {
  final Channel channel;
  final CastProvider castProvider;

  const _CastSheet({required this.channel, required this.castProvider});

  @override
  Widget build(BuildContext context) {
    final devices = [
      'Living Room TV',
      'Bedroom Chromecast',
      'Kitchen Display',
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cast_rounded, color: AppTheme.accent),
              const SizedBox(width: 10),
              Text('Cast to Device',
                  style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            castProvider.isConnected
                ? 'Connected to: ${castProvider.connectedDeviceName}'
                : 'Select a device to cast to',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Divider(height: 24),
          ...devices.map((device) => ListTile(
                leading: const Icon(Icons.tv_rounded,
                    color: AppTheme.textSecondary),
                title: Text(device),
                trailing: castProvider.connectedDeviceName == device
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppTheme.accent)
                    : null,
                onTap: () {
                  castProvider.connect(device).then((_) {
                    castProvider.castChannel(channel.streamUrl, channel.name);
                    Navigator.pop(context);
                  });
                },
              )),
          if (castProvider.isConnected)
            ListTile(
              leading:
                  const Icon(Icons.stop_rounded, color: AppTheme.error),
              title: const Text('Stop Casting',
                  style: TextStyle(color: AppTheme.error)),
              onTap: () {
                castProvider.disconnect();
                Navigator.pop(context);
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
