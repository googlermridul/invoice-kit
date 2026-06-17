import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Reactive connectivity service.
class ConnectivityService {
  ConnectivityService([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  final StreamController<bool> _controller = StreamController.broadcast();

  Stream<bool> get onConnectionChange => _controller.stream;
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    final result = await _connectivity.checkConnectivity();
    _emit(result);
    _connectivity.onConnectivityChanged.listen(_emit);
  }

  void _emit(List<ConnectivityResult> results) {
    final next = results.any((r) => r != ConnectivityResult.none);
    if (next != _isOnline) {
      _isOnline = next;
      _controller.add(next);
    }
  }

  Future<bool> isConnected() async {
    final result = await _connectivity.checkConnectivity();
    return result.any((r) => r != ConnectivityResult.none);
  }

  Future<void> dispose() => _controller.close();
}
