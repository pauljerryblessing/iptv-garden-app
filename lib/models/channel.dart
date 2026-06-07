class Channel {
  final String id;
  final String name;
  final String streamUrl;
  final String? logoUrl;
  final String category;
  final String? country;
  final String? language;
  final String? epgId;
  final Map<String, String>? headers;
  bool isFavorite;
  DateTime? lastWatched;
  int watchCount;

  Channel({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.logoUrl,
    required this.category,
    this.country,
    this.language,
    this.epgId,
    this.headers,
    this.isFavorite = false,
    this.lastWatched,
    this.watchCount = 0,
  });

  factory Channel.fromM3U(Map<String, String> attributes, String url) {
    final id = attributes['tvg-id'] ??
        attributes['tvg-name'] ??
        url.hashCode.toString();

    return Channel(
      id: id,
      name: attributes['tvg-name'] ?? 'Unknown Channel',
      streamUrl: url,
      logoUrl: attributes['tvg-logo'],
      category: attributes['group-title'] ?? 'General',
      country: attributes['tvg-country'],
      language: attributes['tvg-language'],
      epgId: attributes['tvg-id'],
    );
  }

  Channel copyWith({
    String? id,
    String? name,
    String? streamUrl,
    String? logoUrl,
    String? category,
    String? country,
    String? language,
    bool? isFavorite,
    DateTime? lastWatched,
    int? watchCount,
  }) {
    return Channel(
      id: id ?? this.id,
      name: name ?? this.name,
      streamUrl: streamUrl ?? this.streamUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      category: category ?? this.category,
      country: country ?? this.country,
      language: language ?? this.language,
      epgId: epgId,
      headers: headers,
      isFavorite: isFavorite ?? this.isFavorite,
      lastWatched: lastWatched ?? this.lastWatched,
      watchCount: watchCount ?? this.watchCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'streamUrl': streamUrl,
        'logoUrl': logoUrl,
        'category': category,
        'country': country,
        'language': language,
        'epgId': epgId,
        'isFavorite': isFavorite,
        'lastWatched': lastWatched?.toIso8601String(),
        'watchCount': watchCount,
      };

  factory Channel.fromJson(Map<String, dynamic> json) => Channel(
        id: json['id'] as String,
        name: json['name'] as String,
        streamUrl: json['streamUrl'] as String,
        logoUrl: json['logoUrl'] as String?,
        category: json['category'] as String? ?? 'General',
        country: json['country'] as String?,
        language: json['language'] as String?,
        epgId: json['epgId'] as String?,
        isFavorite: json['isFavorite'] as bool? ?? false,
        lastWatched: json['lastWatched'] != null
            ? DateTime.parse(json['lastWatched'] as String)
            : null,
        watchCount: json['watchCount'] as int? ?? 0,
      );
}
