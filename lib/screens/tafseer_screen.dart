import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quraan_tafseer/constants/colors.dart';

class TafsirScreen extends StatefulWidget {
  final String surahName;
  // ignore: non_constant_identifier_names
  final String EnglishName;

  const TafsirScreen({
    super.key,
    required this.surahName,
    required this.EnglishName,
  });

  @override
  State<TafsirScreen> createState() => _TafsirScreenState();
}

class _TafsirScreenState extends State<TafsirScreen> {
  List<dynamic> ayat = [];
  List<dynamic> filteredAyat = [];
  int? openedIndex;
  int? selectedAyahNumber;

  @override
  void initState() {
    super.initState();
    _loadJson();
  }

  Future<void> _loadJson() async {
    final response = await rootBundle.loadString(
      'assets/json/tafseer/${widget.EnglishName}.json',
    );
    final data = json.decode(response);
    if (data != null && data['ayahs'] != null) {
      setState(() {
        ayat = data['ayahs'];
        filteredAyat = ayat;
      });
    }
  }

  void _filterByAyah(int number) {
    setState(() {
      selectedAyahNumber = number;
      filteredAyat = ayat.where((a) => a['number'] == number).toList();
      openedIndex = 0;
    });
    Navigator.pop(context);
  }

  void _clearFilter() {
    setState(() {
      selectedAyahNumber = null;
      filteredAyat = ayat;
      openedIndex = null;
    });
  }

  void _showAyahSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر آية'),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ayat.map<Widget>((ayah) {
              return GestureDetector(
                onTap: () => _filterByAyah(ayah['number']),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Text(
                    '${ayah['number']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("تفسير سورة ${widget.surahName}"),
        backgroundColor: MyColors.deepBlue,
        foregroundColor: MyColors.lightWhite,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: _showAyahSelector,
                  child: const Text("اختر اية"),
                ),
                const SizedBox(width: 8),
                if (selectedAyahNumber != null)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: _clearFilter,
                    icon: const Icon(Icons.close, color: MyColors.lightBeige),
                    label: const Text(
                      "Clear",
                      style: TextStyle(color: MyColors.lightWhite),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredAyat.length,
              itemBuilder: (context, index) {
                final ayah = filteredAyat[index];
                final isOpen = openedIndex == index;
                return Column(
                  children: [
                    ListTile(
                      title: Text('تفسير الآية رقم ${ayah['number']}'),
                      trailing: Icon(
                        isOpen ? Icons.expand_less : Icons.expand_more,
                      ),
                      onTap: () =>
                          setState(() => openedIndex = isOpen ? null : index),
                    ),
                    if (isOpen)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("النص: ${ayah['text']}"),
                            const SizedBox(height: 8),
                            Text("التفسير: ${ayah['tafseer']}"),
                            const Divider(),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
