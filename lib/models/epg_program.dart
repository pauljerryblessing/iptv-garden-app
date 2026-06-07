class EpgProgram {
  final String channelId;
  final String title;
  final String? subtitle;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? category;
  final String? icon;
  final String? rating;
  final bool isLive;

  EpgProgram({
    required this.channelId,
    required this.title,
    this.subtitle,
    this.description,
    required this.startTime,
    required this.endTime,
    this.category,
    this.icon,
    this.rating,
  }) : isLive = DateTime.now().isAfter(startTime) && DateTime.now().isBefore(endTime);

  Duration get duration => endTime.difference(startTime);
  Duration get elapsed => isLive ? DateTime.now().difference(startTime) : Duration.zero;

  double get progress {
    if (!isLive) return 0.0;
    final total = duration.inSeconds;
    if (total <= 0) return 0.0;
    return (elapsed.inSeconds / total).clamp(0.0, 1.0);
  }

  String get timeRange {
    String fmt(DateTime dt) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    return '${fmt(startTime)} – ${fmt(endTime)}';
  }

  String get durationLabel {
    final mins = duration.inMinutes;
    if (mins < 60) return '${mins}m';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  factory EpgProgram.fromJson(Map<String, dynamic> json) => EpgProgram(
        channelId: json['channel'] as String,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String?,
        description: json['description'] as String?,
        startTime: DateTime.parse(json['start'] as String),
        endTime: DateTime.parse(json['stop'] as String),
        category: json['category'] as String?,
        icon: json['icon'] as String?,
        rating: json['rating'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'channel': channelId,
        'title': title,
        'subtitle': subtitle,
        'description': description,
        'start': startTime.toIso8601String(),
        'stop': endTime.toIso8601String(),
        'category': category,
        'icon': icon,
        'rating': rating,
      };
}

class ChannelSchedule {
  final String channelId;
  final List<EpgProgram> programs;

  const ChannelSchedule({required this.channelId, required this.programs});

  EpgProgram? get nowPlaying {
    final now = DateTime.now();
    try {
      return programs.firstWhere(
        (p) => now.isAfter(p.startTime) && now.isBefore(p.endTime),
      );
    } catch (_) {
      return null;
    }
  }

  EpgProgram? get nextUp {
    final now = DateTime.now();
    try {
      return programs.firstWhere((p) => p.startTime.isAfter(now));
    } catch (_) {
      return null;
    }
  }

  List<EpgProgram> get upcoming {
    final now = DateTime.now();
    return programs.where((p) => p.endTime.isAfter(now)).toList();
  }

  List<EpgProgram> programsForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return programs
        .where((p) => p.startTime.isAfter(start) && p.startTime.isBefore(end))
        .toList();
  }
}
