enum ErpProvider { odoo, sap, zoho, customWebhook, csv }

enum SyncStatus { running, completed, failed }

class ErpIntegration {
  final String id;
  final String vendorId;
  final ErpProvider provider;
  final String displayName;
  final bool isActive;
  final String? webhookUrl;
  final String? apiUrl;
  final int syncIntervalMinutes;
  final DateTime? lastSyncAt;
  final String? lastSyncStatus;
  final Map<String, dynamic> fieldMapping;

  const ErpIntegration({
    required this.id,
    required this.vendorId,
    required this.provider,
    required this.displayName,
    required this.isActive,
    this.webhookUrl,
    this.apiUrl,
    required this.syncIntervalMinutes,
    this.lastSyncAt,
    this.lastSyncStatus,
    this.fieldMapping = const {},
  });
}

class ErpSyncLog {
  final int id;
  final String integrationId;
  final String syncType;
  final String direction;
  final int recordsProcessed;
  final int recordsSucceeded;
  final int recordsFailed;
  final SyncStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? errorDetails;

  const ErpSyncLog({
    required this.id,
    required this.integrationId,
    required this.syncType,
    required this.direction,
    required this.recordsProcessed,
    required this.recordsSucceeded,
    required this.recordsFailed,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.errorDetails,
  });
}