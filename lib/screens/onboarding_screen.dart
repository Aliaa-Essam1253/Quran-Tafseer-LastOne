import 'package:flutter/material.dart';
import 'package:quraan_tafseer/constants/colors.dart';
import 'package:quraan_tafseer/screens/main_navigation_screen.dart';
import 'package:quraan_tafseer/utils/ui_utils.dart';

import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      'image': 'assets/images/onboarding2.png',
      'title': 'قراءة سهلة',
      'desc': 'تصفح القرآن الكريم بسلاسة ووضوح',
    },
    {
      'image': 'assets/images/onboarding3.png',
      'title': 'تفسير مبسط',
      'desc': 'تعرف على المعاني بطريقة سهلة',
    },
    {
      'image': 'assets/images/onboarding4.png',
      'title': 'ابدأ الآن',
      'desc': 'املأ قلبك بذكر الله وابدأ رحلتك اليوم',
    },
  ];

  void finishOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: onboardingData.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(onboardingData[index]['image']!, height: 200),
                  const SizedBox(height: 30),
                  Text(
                    onboardingData[index]['title']!,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      onboardingData[index]['desc']!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              onboardingData.length,
              (i) => buildDot(i, _currentPage),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: finishOnboarding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyColors.deepBlue,
                      foregroundColor: MyColors.lightWhite,
                    ),
                    child: Text(
                      _currentPage == onboardingData.length - 1
                          ? "Start"
                          : "Next",
                    ),
                  ),
                ),
                if (_currentPage != onboardingData.length - 1) ...[
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: finishOnboarding,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MyColors.deepBlue,
                        foregroundColor: MyColors.lightWhite,
                      ),
                      child: const Text("Skip"),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
