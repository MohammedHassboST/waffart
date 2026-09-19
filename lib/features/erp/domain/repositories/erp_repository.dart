import '../entities/erp_integration.dart';

abstract class ErpRepository {
  Future<List<ErpIntegration>> getIntegrations(String vendorId);
  Future<ErpIntegration> createIntegration({
    required String vendorId,
    required ErpProvider provider,
    required String displayName,
    String? webhookUrl,
    String? apiUrl,
    String? apiKey,
    String? apiSecret,
    Map<String, dynamic>? fieldMapping,
  });
  Future<void> updateIntegration(ErpIntegration integration);
  Future<void> deleteIntegration(String id);
  Future<void> triggerSync(String integrationId, {bool full = false});
  Future<List<ErpSyncLog>> getSyncLogs(String integrationId, {int limit = 50});
  Future<void> mapSku({
    required String integrationId,
    required String localProductId,
    required String externalSku,
    String? variantId,
  });
}