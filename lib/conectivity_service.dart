import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  late final StreamSubscription<List<ConnectivityResult>> _sub;

  ConnectivityService() {
    _checkNow();
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online != _isOnline) {
        _isOnline = online;
        notifyListeners();
      }
    });
  }

  Future<void> _checkNow() async {
    final results = await Connectivity().checkConnectivity();
    _isOnline = results.any((r) => r != ConnectivityResult.none);
    notifyListeners();
  }

  Future<bool> check() async {
    await _checkNow();
    return _isOnline;
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
