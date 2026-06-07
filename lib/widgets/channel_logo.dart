import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

class ChannelLogo extends StatelessWidget {
  final String? logoUrl;
  final double size;
  final double borderRadius;

  const ChannelLogo({
    super.key,
    this.logoUrl,
    required this.size,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    if (logoUrl == null || logoUrl!.isEmpty) {
      return _placeholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: logoUrl!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholder: (_, __) => _placeholder(),
        errorWidget: (_, __, ___) => _placeholder(),
        httpHeaders: const {'User-Agent': 'IPTVGarden/1.0'},
        memCacheWidth: (size * 2).toInt(),
        memCacheHeight: (size * 2).toInt(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(
        Icons.tv_rounded,
        size: size * 0.5,
        color: AppTheme.textMuted,
      ),
    );
  }
}
