import '../models/channel.dart';

class M3UParser {
  static List<Channel> parse(String content) {
    final List<Channel> channels = [];
    final lines = content.split('\n');

    if (lines.isEmpty || !lines.first.trim().startsWith('#EXTM3U')) {
      return channels;
    }

    Map<String, String> currentAttributes = {};
    String? currentName;

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.isEmpty) continue;

      if (line.startsWith('#EXTINF:')) {
        currentAttributes = {};
        currentName = null;
        _parseExtInf(line, currentAttributes);
        currentName = _extractName(line);
      } else if (line.startsWith('#')) {
        continue;
      } else if (line.isNotEmpty && !line.startsWith('#')) {
        // This is a stream URL
        if (currentName != null) {
          currentAttributes['tvg-name'] ??= currentName;
          _normalizeCategory(currentAttributes);
          final channel = Channel.fromM3U(currentAttributes, line);
          channels.add(channel);
        }
        currentAttributes = {};
        currentName = null;
      }
    }

    return channels;
  }

  static void _parseExtInf(String line, Map<String, String> attributes) {
    // Extract all tvg- attributes
    final patterns = [
      RegExp(r'tvg-id="([^"]*)"'),
      RegExp(r'tvg-name="([^"]*)"'),
      RegExp(r'tvg-logo="([^"]*)"'),
      RegExp(r'tvg-country="([^"]*)"'),
      RegExp(r'tvg-language="([^"]*)"'),
      RegExp(r'group-title="([^"]*)"'),
    ];

    final keys = [
      'tvg-id',
      'tvg-name',
      'tvg-logo',
      'tvg-country',
      'tvg-language',
      'group-title',
    ];

    for (int i = 0; i < patterns.length; i++) {
      final match = patterns[i].firstMatch(line);
      if (match != null && match.group(1)!.isNotEmpty) {
        attributes[keys[i]] = match.group(1)!;
      }
    }
  }

  static String? _extractName(String line) {
    final commaIndex = line.lastIndexOf(',');
    if (commaIndex != -1 && commaIndex < line.length - 1) {
      return line.substring(commaIndex + 1).trim();
    }
    return null;
  }

  static void _normalizeCategory(Map<String, String> attributes) {
    final raw = attributes['group-title'] ?? '';
    attributes['group-title'] = _mapToKnownCategory(raw);
  }

  static String _mapToKnownCategory(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('news')) return 'News';
    if (lower.contains('sport') || lower.contains('football') || lower.contains('soccer')) return 'Sports';
    if (lower.contains('movie') || lower.contains('film') || lower.contains('cinema')) return 'Movies';
    if (lower.contains('entertain') || lower.contains('general') || lower.contains('lifestyle')) return 'Entertainment';
    if (lower.contains('kid') || lower.contains('child') || lower.contains('cartoon') || lower.contains('anime')) return 'Kids';
    if (lower.contains('music')) return 'Music';
    if (lower.contains('docu') || lower.contains('nature') || lower.contains('science') || lower.contains('history')) return 'Documentary';
    if (raw.isNotEmpty) return 'International';
    return 'Entertainment';
  }
}
