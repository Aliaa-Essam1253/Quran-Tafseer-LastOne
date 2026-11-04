import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quraan_tafseer/theme/theme_provider.dart';
import 'package:quraan_tafseer/constants/colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final currentFontLevel = themeProvider.currentFontLevel;

    double getFontSize(int level) {
      switch (level) {
        case 0:
          return 16.0;
        case 2:
          return 20.0;
        default:
          return 18.0;
      }
    }

    final fontSize = getFontSize(currentFontLevel);
    final textColor = isDarkMode ? Colors.white : Colors.black;

   return Scaffold(
  body: Directionality(
    textDirection: TextDirection.rtl,
    child: ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          'إعدادات التطبيق',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          activeColor: MyColors.deepBlue,
          title: Text(
            'الوضع الليلي',
            style: TextStyle(fontSize: fontSize, color: textColor),
          ),
          value: isDarkMode,
          onChanged: themeProvider.toggleDarkMode,
        ),
        const Divider(),
        ListTile(
          title: Text(
            'حجم الخط',
            style: TextStyle(fontSize: fontSize, color: textColor),
          ),
          subtitle: Slider(
            value: currentFontLevel.toDouble(),
            min: 0,
            max: 2,
            divisions: 2,
            label: ['صغير', 'متوسط', 'كبير'][currentFontLevel],
            onChanged: (value) => themeProvider.setFontLevel(value.toInt()),
            activeColor: MyColors.deepBlue,
          ),
        ),
        const Divider(),
        ListTile(
          title: Text(
            'حول التطبيق',
            style: TextStyle(fontSize: fontSize, color: textColor),
          ),
          trailing: Icon(Icons.info_outline, color: textColor),
          onTap: () => showAboutDialog(
            context: context,
            applicationName: 'التفسير السعيد',
            applicationVersion: 'الإصدار 2 + 1.0.1',
            children: const [
              Text(
                'تطبيق متكامل لقراءة القرآن الكريم والاستماع إليه وتصفح التفسير بسهولة',
              ),
              SizedBox(height: 8),
              Text('سيتم إضافة سياسة الخصوصية قريبًا'),
            ],
          ),
        ),
      ],
    ),
  ),
);
  }
}
