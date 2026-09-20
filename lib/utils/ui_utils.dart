// ── HomeButton ────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:quraan_tafseer/constants/colors.dart';
import 'package:quraan_tafseer/constants/styles.dart';
import 'package:quraan_tafseer/models/surah_model.dart';

class HomeButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;

  const HomeButton({
    super.key,
    required this.title,
    required this.onTap,
    this.color = MyColors.deepBlue,
    this.textColor = MyColors.lightWhite,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: elevatedButtonStyle(color),
      child: Text(title, style: TextStyle(color: textColor)),
    );
  }
}

// ── Page dot indicator ────────────────────────────────────────────────────────

Widget buildDot(int index, int currentPage) {
  return Container(
    height: currentPage == index ? 12 : 8,
    width: currentPage == index ? 12 : 8,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    decoration: BoxDecoration(
      color: currentPage == index ? MyColors.deepGreen : MyColors.darkGrey,
      shape: BoxShape.circle,
    ),
  );
}

// ── Surah card (used in TafseerListScreen) ────────────────────────────────────

Widget surahCard(BuildContext context, Surah surah, VoidCallback onTap) {
  return Card(
    surfaceTintColor: MyColors.lightBeige,
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: MyColors.deepBlue,
        child: Text(
          '${surah.number}',
          style: const TextStyle(color: MyColors.lightWhite),
        ),
      ),
      title: Text(
        surah.name,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(surah.type),
      trailing: Text('${surah.ayahCount} آية'),
      onTap: onTap,
    ),
  );
}
