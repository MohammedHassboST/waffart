import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/admin_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة تحكم الأدمن'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'طلبات الموافقة', icon: Icon(Icons.pending_actions)),
              Tab(text: 'كل الموردين', icon: Icon(Icons.store)),
              Tab(text: 'كل الطلبات', icon: Icon(Icons.receipt)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PendingVendorsTab(),
            _AllVendorsTab(),
            _AllOrdersTab(),
          ],
        ),
      ),
    );
  }
}

class _PendingVendorsTab extends ConsumerWidget {
  const _PendingVendorsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingVendorsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (vendors) {
        if (vendors.isEmpty) return const Center(child: Text('لا يوجد طلبات'));
        return ListView.builder(
          itemCount: vendors.length,
          itemBuilder: (_, i) {
            final v = vendors[i];
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(v['store_name']),
                subtitle: Text('${v['profiles']?['full_name']} - ${v['profiles']?['phone']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () =>
                          ref.read(approveVendorProvider)(v['id'], true),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () =>
                          ref.read(approveVendorProvider)(v['id'], false),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AllVendorsTab extends ConsumerWidget {
  const _AllVendorsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allVendorsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (vendors) => ListView.builder(
        itemCount: vendors.length,
        itemBuilder: (_, i) {
          final v = vendors[i];
          return ListTile(
            leading: Icon(
              v['is_approved'] == true ? Icons.verified : Icons.pending,
              color: v['is_approved'] == true ? Colors.green : Colors.orange,
            ),
            title: Text(v['store_name']),
            subtitle: Text(v['profiles']?['full_name'] ?? ''),
          );
        },
      ),
    );
  }
}

class _AllOrdersTab extends ConsumerWidget {
  const _AllOrdersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allOrdersProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (orders) => ListView.builder(
        itemCount: orders.length,
        itemBuilder: (_, i) {
          final o = orders[i];
          return ListTile(
            title: Text(o['order_number']),
            subtitle: Text(o['profiles']?['full_name'] ?? ''),
            trailing: Text(
              Formatters.currency((o['total_amount'] as num).toDouble()),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }
}