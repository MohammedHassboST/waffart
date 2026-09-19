import 'package:supabase_flutter/supabase_flutter.dart';
import '../monitoring/supabase_perf_monitor.dart';

class InstrumentedSupabaseClient {
  final SupabaseClient _client;
  InstrumentedSupabaseClient(this._client);

  /// استعلام آمن مع تتبع
  PostgrestFilterBuilder<PostgrestList> select(String table) {
    return _client.from(table).select();
  }

  /// استدعاء RPC مع تتبع
  Future<dynamic> rpc(
      String functionName, {
        Map<String, dynamic>? params,
      }) async {
    return SupabasePerfMonitor.track(
      'RPC:$functionName',
          () => _client.rpc(functionName, params: params),
    );
  }

  /// إدراج مع تتبع
  Future<dynamic> insert(
      String table,
      dynamic values,
      ) async {
    return SupabasePerfMonitor.track(
      'INSERT:$table',
          () => _client.from(table).insert(values).select(),
    );
  }

  SupabaseClient get raw => _client;
}