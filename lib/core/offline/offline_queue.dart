import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/supabase_client.dart';

class OfflineAction {
  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  int retries;

  OfflineAction({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.retries = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'payload': payload,
    'created_at': createdAt.toIso8601String(),
    'retries': retries,
  };

  factory OfflineAction.fromJson(Map<String, dynamic> json) => OfflineAction(
    id: json['id'] as String,
    type: json['type'] as String,
    payload: Map<String, dynamic>.from(json['payload']),
    createdAt: DateTime.parse(json['created_at'] as String),
    retries: json['retries'] as int? ?? 0,
  );
}

class OfflineQueueNotifier extends StateNotifier<List<OfflineAction>> {
  OfflineQueueNotifier() : super([]) {
    _init();
  }

  StreamSubscription? _sub;
  static const int maxRetries = 3;

  Future<void> _init() async {
    _loadFromStorage();
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        processQueue();
      }
    });
  }

  void _loadFromStorage() {
    // TODO: قم بالتحميل من HiveCacheService
  }

  void enqueue(OfflineAction action) {
    state = [...state, action];
    _persist();
  }

  Future<void> processQueue() async {
    if (state.isEmpty) return;

    final remaining = <OfflineAction>[];
    for (final action in state) {
      final success = await _execute(action);
      if (!success && action.retries < maxRetries) {
        action.retries++;
        remaining.add(action);
      }
    }
    state = remaining;
    _persist();
  }

  Future<bool> _execute(OfflineAction action) async {
    try {
      switch (action.type) {
        case 'confirm_order':
          await SupabaseClientProvider.client.rpc(
            'confirm_order_atomic',
            params: action.payload,
          );
          return true;
        case 'update_profile':
          await SupabaseClientProvider.client
              .from('profiles')
              .update(action.payload)
              .eq('id', SupabaseClientProvider.client.auth.currentUser!.id);
          return true;
        default:
          return false;
      }
    } catch (_) {
      return false;
    }
  }

  void _persist() {
    // TODO: حفظ في Hive
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final offlineQueueProvider =
StateNotifierProvider<OfflineQueueNotifier, List<OfflineAction>>(
      (ref) => OfflineQueueNotifier(),
);