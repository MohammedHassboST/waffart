import '../../../../core/network/supabase_client.dart';
import '../../domain/entities/erp_integration.dart';
import '../../domain/repositories/erp_repository.dart';

class ErpRepositoryImpl implements ErpRepository {
  final _client = SupabaseClientProvider.client;

  @override
  Future<List<ErpIntegration>> getIntegrations(String vendorId) async {
    final res = await _client
        .from('erp_integrations')
        .select()
        .eq('vendor_id', vendorId)
        .order('created_at', ascending: false);
    return (res as List).map((e) => _mapIntegration(e)).toList();
  }

  @override
  Future<ErpIntegration> createIntegration({
    required String vendorId,
    required ErpProvider provider,
    required String displayName,
    String? webhookUrl,
    String? apiUrl,
    String? apiKey,
    String? apiSecret,
    Map<String, dynamic>? fieldMapping,
  }) async {
    final res = await _client.from('erp_integrations').insert({
      'vendor_id': vendorId,
      'provider': provider.name,
      'display_name': displayName,
      'webhook_url': webhookUrl,
      'api_url': apiUrl,
      'api_key_encrypted': apiKey, // TODO: Encrypt via Edge Function
      'api_secret_encrypted': apiSecret,
      'field_mapping': fieldMapping ?? {},
    }).select().single();
    return _mapIntegration(res);
  }

  @override
  Future<void> updateIntegration(ErpIntegration integration) async {
    await _client.from('erp_integrations').update({
      'display_name': integration.displayName,
      'is_active': integration.isActive,
      'webhook_url': integration.webhookUrl,
      'api_url': integration.apiUrl,
      'sync_interval_minutes': integration.syncIntervalMinutes,
      'field_mapping': integration.fieldMapping,
    }).eq('id', integration.id);
  }

  @override
  Future<void> deleteIntegration(String id) async {
    await _client.from('erp_integrations').delete().eq('id', id);
  }

  @override
  Future<void> triggerSync(String integrationId, {bool full = false}) async {
    await _client.functions.invoke('erp-sync', body: {
      'integration_id': integrationId,
      'sync_type': full ? 'full' : 'incremental',
    });
  }

  @override
  Future<List<ErpSyncLog>> getSyncLogs(String integrationId,
      {int limit = 50}) async {
    final res = await _client
        .from('erp_sync_logs')
        .select()
        .eq('integration_id', integrationId)
        .order('started_at', ascending: false)
        .limit(limit);
    return (res as List).map((e) => _mapLog(e)).toList();
  }

  @override
  Future<void> mapSku({
    required String integrationId,
    required String localProductId,
    required String externalSku,
    String? variantId,
  }) async {
    await _client.from('erp_sku_mappings').upsert({
      'integration_id': integrationId,
      'local_product_id': localProductId,
      'external_sku': externalSku,
      'external_variant_id': variantId,
    }, onConflict: 'integration_id,external_sku');
  }

  ErpIntegration _mapIntegration(Map<String, dynamic> j) => ErpIntegration(
    id: j['id'],
    vendorId: j['vendor_id'],
    provider: ErpProvider.values.firstWhere(
          (p) => p.name == j['provider'],
      orElse: () => ErpProvider.customWebhook,
    ),
    displayName: j['display_name'],
    isActive: j['is_active'] ?? true,
    webhookUrl: j['webhook_url'],
    apiUrl: j['api_url'],
    syncIntervalMinutes: j['sync_interval_minutes'] ?? 30,
    lastSyncAt: j['last_sync_at'] != null
        ? DateTime.parse(j['last_sync_at'])
        : null,
    lastSyncStatus: j['last_sync_status'],
    fieldMapping: Map<String, dynamic>.from(j['field_mapping'] ?? {}),
  );

  ErpSyncLog _mapLog(Map<String, dynamic> j) => ErpSyncLog(
    id: j['id'],
    integrationId: j['integration_id'],
    syncType: j['sync_type'],
    direction: j['direction'],
    recordsProcessed: j['records_processed'] ?? 0,
    recordsSucceeded: j['records_succeeded'] ?? 0,
    recordsFailed: j['records_failed'] ?? 0,
    status: SyncStatus.values.firstWhere(
          (s) => s.name == j['status'],
      orElse: () => SyncStatus.failed,
    ),
    startedAt: DateTime.parse(j['started_at']),
    completedAt: j['completed_at'] != null
        ? DateTime.parse(j['completed_at'])
        : null,
    errorDetails: j['error_details'] != null
        ? Map<String, dynamic>.from(j['error_details'])
        : null,
  );
}