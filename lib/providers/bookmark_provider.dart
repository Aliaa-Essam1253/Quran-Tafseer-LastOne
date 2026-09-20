import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:quraan_tafseer/models/bookmark_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkProvider with ChangeNotifier {
  final List<Bookmark> _bookmarks = [];

  List<Bookmark> get bookmarks => List.unmodifiable(_bookmarks);

  Future<void> init() async => loadBookmarks();

  void addBookmark(Bookmark bookmark) async {
    _bookmarks.add(bookmark);
    notifyListeners();
    await saveBookmarks();
  }

  void removeBookmark(String id) async {
    _bookmarks.removeWhere((b) => b.id == id);
    notifyListeners();
    await saveBookmarks();
  }

  bool isBookmarked(String id) => _bookmarks.any((b) => b.id == id);

  Future<void> saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'bookmarks',
      _bookmarks.map((b) => json.encode(b.toJson())).toList(),
    );
  }

  Future<void> loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('bookmarks');
    if (saved != null) {
      _bookmarks
        ..clear()
        ..addAll(saved.map((e) => Bookmark.fromJson(json.decode(e))));
      notifyListeners();
    }
  }

  void clearBookmarks() async {
    _bookmarks.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bookmarks');
  }
}
