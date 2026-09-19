import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_providers.dart';

class AdminVendorsTab extends ConsumerStatefulWidget {
  const AdminVendorsTab({super.key});

  @override
  ConsumerState<AdminVendorsTab> createState() => _AdminVendorsTabState();
}

class _AdminVendorsTabState extends ConsumerState<AdminVendorsTab> {
  String _query = '';
  bool _showOnlyPending = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(allVendorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الموردون'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'ابحث عن مورد...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('بانتظار الموافقة فقط'),
                      selected: _showOnlyPending,
                      onSelected: (v) =>
                          setState(() => _showOnlyPending = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              loading: () =>
              const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('خطأ: $e')),
              data: (vendors) {
                var filtered = vendors;
                if (_showOnlyPending) {
                  filtered = filtered
                      .where((v) => v['is_approved'] != true)
                      .toList();
                }
                if (_query.isNotEmpty) {
                  filtered = filtered
                      .where((v) => (v['store_name'] as String? ?? '')
                      .toLowerCase()
                      .contains(_query.toLowerCase()))
                      .toList();
                }

                if (filtered.isEmpty) {
                  return const Center(child: Text('لا يوجد موردون'));
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(allVendorsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final v = filtered[i];
                      final approved = v['is_approved'] == true;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: approved
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.orange.withValues(alpha: 0.15),
                            child: Icon(
                              approved ? Icons.verified : Icons.pending,
                              color: approved ? Colors.green : Colors.orange,
                            ),
                          ),
                          title: Text(v['store_name'] ?? 'بدون اسم'),
                          subtitle: Text(
                            '${v['profiles']?['full_name'] ?? ''} • ${v['profiles']?['phone'] ?? ''}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: approved
                              ? Chip(
                            label: const Text('معتمد',
                                style: TextStyle(fontSize: 11)),
                            backgroundColor:
                            Colors.green.withValues(alpha: 0.15),
                          )
                              : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check,
                                    color: Colors.green),
                                onPressed: () => ref
                                    .read(approveVendorProvider)(
                                    v['id'], true),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.red),
                                onPressed: () => ref
                                    .read(approveVendorProvider)(
                                    v['id'], false),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}