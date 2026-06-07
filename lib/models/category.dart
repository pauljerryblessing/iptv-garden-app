import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ChannelCategory {
  final String name;
  final IconData icon;
  final Color color;

  const ChannelCategory({
    required this.name,
    required this.icon,
    required this.color,
  });

  static const List<ChannelCategory> predefined = [
    ChannelCategory(
      name: 'All',
      icon: Icons.apps_rounded,
      color: AppTheme.accent,
    ),
    ChannelCategory(
      name: 'News',
      icon: Icons.newspaper_rounded,
      color: Color(0xFF2196F3),
    ),
    ChannelCategory(
      name: 'Sports',
      icon: Icons.sports_soccer_rounded,
      color: Color(0xFF4CAF50),
    ),
    ChannelCategory(
      name: 'Movies',
      icon: Icons.movie_rounded,
      color: Color(0xFFE50914),
    ),
    ChannelCategory(
      name: 'Entertainment',
      icon: Icons.live_tv_rounded,
      color: Color(0xFF9C27B0),
    ),
    ChannelCategory(
      name: 'Kids',
      icon: Icons.child_care_rounded,
      color: Color(0xFFFF9800),
    ),
    ChannelCategory(
      name: 'Music',
      icon: Icons.music_note_rounded,
      color: Color(0xFF00BCD4),
    ),
    ChannelCategory(
      name: 'Documentary',
      icon: Icons.theaters_rounded,
      color: Color(0xFF795548),
    ),
    ChannelCategory(
      name: 'International',
      icon: Icons.language_rounded,
      color: Color(0xFF607D8B),
    ),
  ];
}
