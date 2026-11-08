import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quraan_tafseer/constants/colors.dart';

/// Written version of the book's introduction.
///
/// File format (plain UTF-8 text):
///  • paragraphs are separated by a blank line
///  • a line that starts with "# " is a heading
///  • lines that start with "//" are ignored (comments)
const introTextAsset = 'assets/json/intro.txt';

/// Returns the intro as blocks (headings / paragraphs), or null when the file
/// is missing or has no content yet.
Future<List<String>?> loadIntroBlocks() async {
  try {
    final raw = await rootBundle.loadString(introTextAsset);
    final text = raw
        .split(RegExp(r'\r?\n'))
        .where((l) => !l.trimLeft().startsWith('//'))
        .join('\n');
    final blocks = text
        .split(RegExp(r'\n\s*\n'))
        .map((b) => b.trim())
        .where((b) => b.isNotEmpty)
        .toList();
    return blocks.isEmpty ? null : blocks;
  } catch (_) {
    return null;
  }
}

class IntroTextScreen extends StatefulWidget {
  const IntroTextScreen({super.key});

  @override
  State<IntroTextScreen> createState() => _IntroTextScreenState();
}

class _IntroTextScreenState extends State<IntroTextScreen> {
  late final Future<List<String>?> _future = loadIntroBlocks();
  double _fontSize = 20;

  void _changeSize(double delta) {
    setState(() => _fontSize = (_fontSize + delta).clamp(14.0, 34.0));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white.withOpacity(0.92) : Colors.black87;
    final headingColor = isDark ? MyColors.audioGold : MyColors.deepBlue;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: isDark ? MyColors.darkBlue : MyColors.deepBlue,
          foregroundColor: Colors.white,
          title: const Text('مقدمة التفسير'),
          actions: [
            IconButton(
              tooltip: 'تصغير الخط',
              icon: const Icon(Icons.remove),
              onPressed: () => _changeSize(-2),
            ),
            IconButton(
              tooltip: 'تكبير الخط',
              icon: const Icon(Icons.add),
              onPressed: () => _changeSize(2),
            ),
          ],
        ),
        body: FutureBuilder<List<String>?>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final blocks = snapshot.data;
            if (blocks == null) {
              return const Center(
                child: Text('نص المقدمة غير متاح حاليًا'),
              );
            }
            return SafeArea(
              top: false,
              child: SelectionArea(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  itemCount: blocks.length,
                  itemBuilder: (context, i) {
                    final block = blocks[i];
                    final isHeading = block.startsWith('# ');
                    if (isHeading) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              block.substring(2).trim(),
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: _fontSize + 4,
                                fontWeight: FontWeight.bold,
                                color: headingColor,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 48,
                              height: 2.5,
                              decoration: BoxDecoration(
                                color: MyColors.audioGold,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Text(
                        block,
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: _fontSize,
                          height: 2.0,
                          color: textColor,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}