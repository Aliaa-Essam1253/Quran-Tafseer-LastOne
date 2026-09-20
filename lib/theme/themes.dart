import 'package:flutter/material.dart';
import 'package:quraan_tafseer/constants/colors.dart';

ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  primaryColor: MyColors.deepBlue,
  colorScheme: ColorScheme.light(
    primary: MyColors.deepBlue,
    secondary: MyColors.deepGreen,
    surface: MyColors.lightBeige,
    background: MyColors.lightBeige,
    onSurface: Colors.black87,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      color: Colors.black87,
      fontSize: 28,
      fontWeight: FontWeight.bold,
      fontFamily: 'Cairo',
      height: 1.8,
    ),
    bodyLarge: TextStyle(
      color: Colors.black87,
      fontSize: 16,
      height: 2.0,
      fontFamily: 'Cairo',
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: MyColors.deepGreen,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      fontFamily: 'Cairo',
    ),
    toolbarHeight: 60,
  ),
  switchTheme: SwitchThemeData(
    thumbColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) return MyColors.deepGreen;
      return Colors.grey[300];
    }),
    trackOutlineColor: MaterialStateProperty.resolveWith((states) {
      return states.contains(MaterialState.selected)
          ? MyColors.deepBlue.withOpacity(0.5)
          : Colors.grey.withOpacity(0.3);
    }),
  ),
  cardTheme: CardThemeData(
    color: MyColors.lightWhite,
    elevation: 1.5,
    margin: const EdgeInsets.symmetric(vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  primaryColor: MyColors.deepBlue,
  colorScheme: ColorScheme.dark(
    primary: MyColors.deepBlue,
    secondary: MyColors.lightBeige,
    surface: MyColors.blackShade,
    background: MyColors.blackShade,
    onSurface: Colors.white.withOpacity(0.95),
  ),
  textTheme: TextTheme(
    displayLarge: const TextStyle(
      color: Colors.white,
      fontSize: 28,
      fontWeight: FontWeight.bold,
      fontFamily: 'Cairo',
      height: 1.8,
    ),
    bodyLarge: TextStyle(
      color: Colors.white.withOpacity(0.95),
      fontSize: 16,
      height: 2.0,
      fontFamily: 'Cairo',
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: MyColors.darkGreen,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      fontFamily: 'Cairo',
    ),
    toolbarHeight: 60,
  ),
  switchTheme: SwitchThemeData(
    thumbColor: MaterialStateProperty.resolveWith((states) {
      return states.contains(MaterialState.selected)
          ? MyColors.lightBeige
          : Colors.grey[400]!;
    }),
    trackOutlineColor: MaterialStateProperty.resolveWith((states) {
      return states.contains(MaterialState.selected)
          ? MyColors.lightBeige.withOpacity(0.5)
          : Colors.grey.withOpacity(0.3);
    }),
  ),
  cardTheme: CardThemeData(
    color: MyColors.darkGrey,
    elevation: 2.0,
    margin: const EdgeInsets.symmetric(vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
);
