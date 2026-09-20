import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:quraan_tafseer/conectivity_service.dart';
import 'package:quraan_tafseer/providers/bookmark_provider.dart';
import 'package:quraan_tafseer/providers/quran_provider.dart';
import 'package:quraan_tafseer/quran_api_service.dart';
import 'package:quraan_tafseer/screens/splash_screen.dart';
import 'package:quraan_tafseer/theme/theme_provider.dart';
import 'package:quraan_tafseer/theme/themes.dart';

class QuranTafseer extends StatelessWidget {
  const QuranTafseer({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()..init()),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        ChangeNotifierProvider(create: (_) => QuranProvider(QuranApiService())),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Quraan',
            // Pass font size via theme extensions instead of textTheme.apply()
            // which crashes when any TextStyle has a null fontSize.
            theme: _buildTheme(lightTheme, themeProvider.fontSize),
            darkTheme: _buildTheme(darkTheme, themeProvider.fontSize),
            themeMode: themeProvider.themeMode,
            locale: const Locale('ar', ''),
            supportedLocales: const [Locale('en'), Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const SplashScreen(),
          );
        },
      ),
    );
  }

  /// Safely merges [fontSize] into a theme's textTheme by setting explicit
  /// sizes on every style — no null multiplication, no crash.
  ThemeData _buildTheme(ThemeData base, double fontSize) {
    // Build a complete TextTheme where every style has an explicit fontSize
    // so downstream widgets can scale text by reading ThemeProvider.fontSize.
    final tt = base.textTheme.copyWith(
      displayLarge: (base.textTheme.displayLarge ?? const TextStyle())
          .copyWith(fontFamily: 'Cairo', fontSize: fontSize + 8),
      displayMedium: (base.textTheme.displayMedium ?? const TextStyle())
          .copyWith(fontFamily: 'Cairo', fontSize: fontSize + 4),
      displaySmall: (base.textTheme.displaySmall ?? const TextStyle())
          .copyWith(fontFamily: 'Cairo', fontSize: fontSize + 2),
      headlineLarge: (base.textTheme.headlineLarge ?? const TextStyle())
          .copyWith(fontFamily: 'Cairo', fontSize: fontSize + 2),
      headlineMedium: (base.textTheme.headlineMedium ?? const TextStyle())
          .copyWith(fontFamily: 'Cairo', fontSize: fontSize),
      headlineSmall: (base.textTheme.headlineSmall ?? const TextStyle())
          .copyWith(fontFamily: 'Cairo', fontSize: fontSize),
      titleLarge: (base.textTheme.titleLarge ?? const TextStyle())
          .copyWith(fontFamily: 'Cairo', fontSize: fontSize),
      titleMedium: (base.textTheme.titleMedium ?? const TextStyle())
          .copyWith(fontFamily: 'Cairo', fontSize: fontSize - 2),
      titleSmall: (base.textTheme.titleSmall ?? const TextStyle())
          .copyWith(fontFamily: 'Cairo', fontSize: fontSize - 4),
      bodyLarge: (base.textTheme.bodyLarge ?? const TextStyle())
          .copyWith(fontFamily: 'Cairo', fontSize: fontSize),
      bodyMedium: (base.textTheme.bodyMedium ?? const TextStyle())
          .copyWith(fontFamily: 'Cairo', fontSize: fontSize - 2),
      bodySmall: (base.textTheme.bodySmall ?? const TextStyle())
          .copyWith(fontFamily: 'Cairo', fontSize: fontSize - 4),
      labelLarge: (base.textTheme.labelLarge ?? const TextStyle())
          .copyWith(fontFamily: 'Cairo', fontSize: fontSize - 2),
      labelMedium: (base.textTheme.labelMedium ?? const TextStyle())
          .copyWith(fontFamily: 'Cairo', fontSize: fontSize - 4),
      labelSmall: (base.textTheme.labelSmall ?? const TextStyle())
          .copyWith(fontFamily: 'Cairo', fontSize: fontSize - 6),
    );

    return base.copyWith(textTheme: tt);
  }
}
