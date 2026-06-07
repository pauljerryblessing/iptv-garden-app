import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';

import 'providers/channel_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/recent_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/cast_provider.dart';
import 'providers/epg_provider.dart';
import 'screens/home/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.bgPrimary,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..init()),
        ChangeNotifierProvider(create: (_) => ChannelProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()..init()),
        ChangeNotifierProvider(create: (_) => RecentProvider()..init()),
        ChangeNotifierProvider(create: (_) => CastProvider()..init()),
        ChangeNotifierProvider(create: (_) => EpgProvider()),
      ],
      child: const IPTVGardenApp(),
    ),
  );
}

class IPTVGardenApp extends StatelessWidget {
  const IPTVGardenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'IPTV Garden',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: const HomeScreen(),
        );
      },
    );
  }
}
