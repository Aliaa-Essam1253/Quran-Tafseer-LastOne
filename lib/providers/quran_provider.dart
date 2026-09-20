import 'package:flutter/foundation.dart';
import 'package:quraan_tafseer/download_storage.dart';
import 'package:quraan_tafseer/models/reciter_model.dart';
import 'package:quraan_tafseer/models/surah_model.dart';
import 'package:quraan_tafseer/quran_service_interface.dart';

enum LoadingState { idle, loading, success, error }

class QuranProvider extends ChangeNotifier {
  final IQuranService _service;

  QuranProvider(this._service);

  // ── Surah list ────────────────────────────────────────────────────────────
  List<Surah> _surahs = [];
  List<Surah> get surahs => _surahs;

  Surah? _selectedSurah;
  Surah? get selectedSurah => _selectedSurah;

  LoadingState _surahListState = LoadingState.idle;
  LoadingState get surahListState => _surahListState;

  LoadingState _surahDetailState = LoadingState.idle;
  LoadingState get surahDetailState => _surahDetailState;

  // ── Reciters ──────────────────────────────────────────────────────────────
  List<Reciter> _reciters = [];
  List<Reciter> get reciters => _reciters;

  Reciter? _selectedReciter;
  Reciter? get selectedReciter => _selectedReciter;

  LoadingState _recitersState = LoadingState.idle;
  LoadingState get recitersState => _recitersState;

  // ── Audio ─────────────────────────────────────────────────────────────────
  RecitationAudio? _currentAudio;
  RecitationAudio? get currentAudio => _currentAudio;

  LoadingState _audioState = LoadingState.idle;
  LoadingState get audioState => _audioState;

  bool _audioBarVisible = false;
  bool get audioBarVisible => _audioBarVisible;

  // ── Error ─────────────────────────────────────────────────────────────────
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── Load surahs ───────────────────────────────────────────────────────────
  Future<void> loadSurahs() async {
    if (_surahListState == LoadingState.loading) return;
    _setState(surahList: LoadingState.loading);
    try {
      _surahs = await _service.fetchAllSurahs();
      _setState(surahList: LoadingState.success);
    } catch (e) {
      if (_surahs.isNotEmpty) {
        _setState(surahList: LoadingState.success);
      } else {
        _errorMessage = 'لا يوجد اتصال بالإنترنت ولا توجد بيانات محفوظة';
        _setState(surahList: LoadingState.error);
      }
    }
  }

  // ── Load reciters ─────────────────────────────────────────────────────────
  Future<void> loadReciters() async {
    if (_recitersState == LoadingState.loading) return;
    _setState(reciters: LoadingState.loading);
    try {
      _reciters = await _service.fetchReciters();
      _setState(reciters: LoadingState.success);
    } catch (e) {
      if (_reciters.isNotEmpty) {
        _setState(reciters: LoadingState.success);
      } else {
        _setState(reciters: LoadingState.error);
      }
    }
    await _restoreLastReciter();
  }

  Future<void> _restoreLastReciter() async {
    if (_selectedReciter != null) return;
    final saved = await DownloadStorage.loadLastReciter();
    if (saved == null) return;
    final savedId = saved['id'] as int;
    try {
      _selectedReciter = _reciters.firstWhere((r) => r.id == savedId);
    } catch (_) {
      _selectedReciter = Reciter(
        id: savedId,
        name: saved['name'] as String,
        style: saved['style'] as String?,
      );
    }
    notifyListeners();
  }

  // ── Select surah ──────────────────────────────────────────────────────────
  void selectSurah(Surah surah) {
    _selectedSurah = surah;
    _currentAudio = null;
    notifyListeners();
    _loadSurahDetail(surah.number);
  }

  // ── Select reciter ────────────────────────────────────────────────────────
  void selectReciter(Reciter reciter) {
    _selectedReciter = reciter;
    notifyListeners();
    DownloadStorage.saveLastReciter(reciter.id, reciter.name, reciter.style);
    _maybeLoadAudio();
  }

  Future<void> _loadSurahDetail(int number) async {
    _setState(surahDetail: LoadingState.loading);
    try {
      _selectedSurah = await _service.fetchSurah(number);
      _setState(surahDetail: LoadingState.success);
      _maybeLoadAudio();
    } catch (e) {
      debugPrint('fetchSurah offline: $e');
      _setState(surahDetail: LoadingState.success);
    }
  }

  Future<void> _maybeLoadAudio() async {
    if (_selectedReciter == null || _selectedSurah == null) return;
    _audioBarVisible = true;
    _setState(audio: LoadingState.loading);
    try {
      _currentAudio = await _service.fetchRecitation(
        _selectedReciter!.id,
        _selectedSurah!.number,
      );
      _setState(audio: LoadingState.success);
    } catch (e) {
      debugPrint('fetchRecitation offline: $e');
      _currentAudio = null;
      _setState(audio: LoadingState.idle);
    }
  }

  void retry() {
    _errorMessage = null;
    notifyListeners();
    if (_surahListState == LoadingState.error) loadSurahs();
    if (_recitersState == LoadingState.error) loadReciters();
    if (_surahDetailState == LoadingState.error && _selectedSurah != null) {
      _loadSurahDetail(_selectedSurah!.number);
    }
  }

  void _setState({
    LoadingState? surahList,
    LoadingState? surahDetail,
    LoadingState? reciters,
    LoadingState? audio,
  }) {
    if (surahList != null) _surahListState = surahList;
    if (surahDetail != null) _surahDetailState = surahDetail;
    if (reciters != null) _recitersState = reciters;
    if (audio != null) _audioState = audio;
    notifyListeners();
  }
}
