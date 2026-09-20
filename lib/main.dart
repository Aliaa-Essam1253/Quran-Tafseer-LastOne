import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quraan_tafseer/conectivity_service.dart';
import 'package:quraan_tafseer/providers/bookmark_provider.dart';
import 'package:quraan_tafseer/providers/quran_provider.dart';
import 'package:quraan_tafseer/quran_api_service.dart';
import 'package:quraan_tafseer/quran_tafseer.dart';
import 'package:quraan_tafseer/theme/theme_provider.dart';
import 'google_drive_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()..init()),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        ChangeNotifierProvider(create: (_) => QuranProvider(QuranApiService())),
      ],
      child: const QuranTafseer(),
    ),
  );
}
