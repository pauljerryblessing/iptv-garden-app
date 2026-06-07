class PlaylistSource {
  final String name;
  final String url;
  final String? description;
  final bool isDefault;

  const PlaylistSource({
    required this.name,
    required this.url,
    this.description,
    this.isDefault = false,
  });

  // IPTV Garden sources - these are publicly available M3U playlists
  static const List<PlaylistSource> iptvGardenSources = [
    PlaylistSource(
      name: 'IPTV Garden - All Channels',
      url: 'https://iptv-org.github.io/iptv/index.m3u',
      description: 'Complete channel list from iptv-org (8000+ channels)',
      isDefault: true,
    ),
    PlaylistSource(
      name: 'IPTV Garden - News',
      url: 'https://iptv-org.github.io/iptv/categories/news.m3u',
      description: 'News channels worldwide',
    ),
    PlaylistSource(
      name: 'IPTV Garden - Sports',
      url: 'https://iptv-org.github.io/iptv/categories/sports.m3u',
      description: 'Sports channels worldwide',
    ),
    PlaylistSource(
      name: 'IPTV Garden - Movies',
      url: 'https://iptv-org.github.io/iptv/categories/movies.m3u',
      description: 'Movie channels worldwide',
    ),
    PlaylistSource(
      name: 'IPTV Garden - Kids',
      url: 'https://iptv-org.github.io/iptv/categories/kids.m3u',
      description: 'Kids channels worldwide',
    ),
    PlaylistSource(
      name: 'IPTV Garden - Music',
      url: 'https://iptv-org.github.io/iptv/categories/music.m3u',
      description: 'Music channels worldwide',
    ),
    PlaylistSource(
      name: 'IPTV Garden - Documentary',
      url: 'https://iptv-org.github.io/iptv/categories/documentary.m3u',
      description: 'Documentary channels worldwide',
    ),
  ];
}
