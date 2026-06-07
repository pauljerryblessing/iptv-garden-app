import '../models/epg_program.dart';

/// Parses XMLTV format EPG data.
/// XMLTV format: https://wiki.xmltv.org/index.php/XMLTVFormat
class XmltvParser {
  static Map<String, ChannelSchedule> parse(String xmlContent) {
    final Map<String, List<EpgProgram>> channelPrograms = {};

    try {
      // Extract all <programme> blocks
      final programmeRegex = RegExp(
        r'<programme\s([^>]+)>(.*?)</programme>',
        dotAll: true,
      );

      for (final match in programmeRegex.allMatches(xmlContent)) {
        final attrs = match.group(1) ?? '';
        final body = match.group(2) ?? '';

        final channelId = _attr(attrs, 'channel');
        final startStr = _attr(attrs, 'start');
        final stopStr = _attr(attrs, 'stop');

        if (channelId.isEmpty || startStr.isEmpty || stopStr.isEmpty) continue;

        final start = _parseXmltvTime(startStr);
        final stop = _parseXmltvTime(stopStr);
        if (start == null || stop == null) continue;

        final title = _tag(body, 'title');
        if (title.isEmpty) continue;

        final program = EpgProgram(
          channelId: channelId,
          title: _decodeEntities(title),
          subtitle: _decodeEntities(_tag(body, 'sub-title')).nullIfEmpty,
          description: _decodeEntities(_tag(body, 'desc')).nullIfEmpty,
          startTime: start,
          endTime: stop,
          category: _decodeEntities(_tag(body, 'category')).nullIfEmpty,
          icon: _iconUrl(body),
          rating: _tag(body, 'value').nullIfEmpty,
        );

        channelPrograms.putIfAbsent(channelId, () => []).add(program);
      }
    } catch (_) {
      // Return whatever we got
    }

    // Sort programs by start time and build schedules
    return channelPrograms.map((id, programs) {
      programs.sort((a, b) => a.startTime.compareTo(b.startTime));
      return MapEntry(id, ChannelSchedule(channelId: id, programs: programs));
    });
  }

  static String _attr(String attrs, String name) {
    final re = RegExp('$name="([^"]*)"');
    return re.firstMatch(attrs)?.group(1) ?? '';
  }

  static String _tag(String body, String tag) {
    final re = RegExp('<$tag[^>]*>([^<]*)</$tag>', dotAll: true);
    return re.firstMatch(body)?.group(1)?.trim() ?? '';
  }

  static String? _iconUrl(String body) {
    final re = RegExp(r'<icon\s+src="([^"]+)"');
    return re.firstMatch(body)?.group(1);
  }

  // XMLTV time format: 20240607143000 +0000
  static DateTime? _parseXmltvTime(String s) {
    try {
      final clean = s.trim().split(' ');
      final ts = clean[0];
      if (ts.length < 14) return null;

      final year = int.parse(ts.substring(0, 4));
      final month = int.parse(ts.substring(4, 6));
      final day = int.parse(ts.substring(6, 8));
      final hour = int.parse(ts.substring(8, 10));
      final min = int.parse(ts.substring(10, 12));
      final sec = int.parse(ts.substring(12, 14));

      // Parse timezone offset if present
      int offsetMin = 0;
      if (clean.length > 1) {
        final tz = clean[1];
        if (tz.length >= 5) {
          final sign = tz[0] == '-' ? -1 : 1;
          final tzH = int.tryParse(tz.substring(1, 3)) ?? 0;
          final tzM = int.tryParse(tz.substring(3, 5)) ?? 0;
          offsetMin = sign * (tzH * 60 + tzM);
        }
      }

      final utc = DateTime.utc(year, month, day, hour, min, sec)
          .subtract(Duration(minutes: offsetMin));
      return utc.toLocal();
    } catch (_) {
      return null;
    }
  }

  static String _decodeEntities(String s) {
    return s
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'");
  }
}

extension _StringExt on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
