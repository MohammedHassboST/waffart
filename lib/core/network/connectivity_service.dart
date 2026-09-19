import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus { online, offline, slow }

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _sub;
  final _controller = StreamController<NetworkStatus>.broadcast();

  Stream<NetworkStatus> get statusStream => _controller.stream;

  ConnectivityService() {
    _init();
  }

  void _init() {
    _connectivity.onConnectivityChanged.listen((results) {
      if (results.contains(ConnectivityResult.none)) {
        _controller.add(NetworkStatus.offline);
      } else if (results.contains(ConnectivityResult.mobile) &&
          !results.contains(ConnectivityResult.wifi)) {
        _controller.add(NetworkStatus.slow);
      } else {
        _controller.add(NetworkStatus.online);
      }
    });
  }

  Future<NetworkStatus> check() async {
    final results = await _connectivity.checkConnectivity();
    if (results.contains(ConnectivityResult.none)) {
      return NetworkStatus.offline;
    }
    return NetworkStatus.online;
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(service.dispose);
  return service;
});

final networkStatusProvider = StreamProvider<NetworkStatus>((ref) {
  return ref.watch(connectivityServiceProvider).statusStream;
});