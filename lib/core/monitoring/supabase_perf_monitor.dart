import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabasePerfMonitor {
  static final List<PerfLog> _logs = [];
  static const int _maxLogs = 100;

  /// غلاف لأي استعلام لتتبع الوقت
  static Future<T> track<T>(
      String operation,
      Future<T> Function() fn,
      ) async {
    final sw = Stopwatch()..start();
    try {
      final result = await fn();
      sw.stop();
      _log(PerfLog(
        operation: operation,
        duration: sw.elapsedMilliseconds,
        success: true,
        timestamp: DateTime.now(),
      ));
      return result;
    } catch (e) {
      sw.stop();
      _log(PerfLog(
        operation: operation,
        duration: sw.elapsedMilliseconds,
        success: false,
        error: e.toString(),
        timestamp: DateTime.now(),
      ));
      rethrow;
    }
  }

  static void _log(PerfLog log) {
    _logs.add(log);
    if (_logs.length > _maxLogs) _logs.removeAt(0);

    if (kDebugMode) {
      final emoji = log.success ? '✅' : '❌';
      debugPrint(
        '$emoji [${log.duration}ms] ${log.operation}'
            '${log.error != null ? ' - ${log.error}' : ''}',
      );
    }
  }

  static List<PerfLog> get logs => List.unmodifiable(_logs);

  static List<PerfLog> get slowQueries =>
      _logs.where((l) => l.duration > 1000).toList();

  static Map<String, int> get avgByOperation {
    final grouped = <String, List<int>>{};
    for (final log in _logs) {
      grouped.putIfAbsent(log.operation, () => []).add(log.duration);
    }
    return grouped.map((k, v) =>
        MapEntry(k, v.reduce((a, b) => a + b) ~/ v.length));
  }
}

class PerfLog {
  final String operation;
  final int duration;
  final bool success;
  final String? error;
  final DateTime timestamp;

  PerfLog({
    required this.operation,
    required this.duration,
    required this.success,
    this.error,
    required this.timestamp,
  });
}