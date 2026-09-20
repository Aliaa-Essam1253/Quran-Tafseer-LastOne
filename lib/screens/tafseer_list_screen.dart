import 'package:flutter/material.dart';
import 'package:quraan_tafseer/models/surah_model.dart';
import 'package:quraan_tafseer/screens/tafseer_screen.dart';
import 'package:quraan_tafseer/utils/function_utils.dart';
import 'package:quraan_tafseer/utils/ui_utils.dart';

class TafseerListScreen extends StatefulWidget {
  const TafseerListScreen({super.key});

  @override
  State<TafseerListScreen> createState() => _TafseerListScreenState();
}

class _TafseerListScreenState extends State<TafseerListScreen> {
  List<Surah> surahs = [];
  List<Surah> filteredSurahs = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  Future<void> _loadSurahs() async {
    final loaded = await loadSurahs();
    setState(() {
      surahs = loaded;
      filteredSurahs = loaded;
    });
  }

  void filterSurahs(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      filteredSurahs = surahs
          .where(
            (s) =>
                s.name.toLowerCase().contains(q) ||
                s.type.toLowerCase().contains(q),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: surahs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    onChanged: filterSurahs,
                    decoration: InputDecoration(
                      hintText: 'ابحث باسم السورة أو نوعها (مكية / مدنية)',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredSurahs.length,
                    itemBuilder: (context, index) => surahCard(
                      context,
                      filteredSurahs[index],
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TafsirScreen(
                            surahName: filteredSurahs[index].name,
                            EnglishName: filteredSurahs[index].englishName,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
