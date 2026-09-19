import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../vendor_dashboard/presentation/providers/vendor_providers.dart';
import '../../data/repositories/erp_repository_impl.dart';
import '../../domain/entities/erp_integration.dart';
import '../../domain/repositories/erp_repository.dart';

final erpRepositoryProvider = Provider<ErpRepository>((ref) {
  return ErpRepositoryImpl();
});

final integrationsProvider =
FutureProvider<List<ErpIntegration>>((ref) async {
  final vendor = await ref.watch(currentVendorProvider.future);
  if (vendor == null) return [];
  return ref.watch(erpRepositoryProvider).getIntegrations(vendor['id']);
});

final syncLogsProvider =
FutureProvider.family<List<ErpSyncLog>, String>((ref, integrationId) {
  return ref.watch(erpRepositoryProvider).getSyncLogs(integrationId);
});