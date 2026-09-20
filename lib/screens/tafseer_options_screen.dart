import 'package:flutter/material.dart';
import 'package:quraan_tafseer/constants/colors.dart';
import 'package:quraan_tafseer/constants/sizes.dart';
import 'package:quraan_tafseer/screens/tafseer_audio_screen.dart';
import 'package:quraan_tafseer/screens/tafseer_list_screen.dart';
import 'package:quraan_tafseer/utils/ui_utils.dart';

class TafseerOptionsScreen extends StatelessWidget {
  const TafseerOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفسير القرآن'),
        backgroundColor: MyColors.deepBlue,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HomeButton(
              title: 'قراءة تفسير القرآن',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TafseerListScreen()),
              ),
            ),
            height16,
            HomeButton(
              title: 'سماع تفسير القرآن',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TafseerAudioScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
