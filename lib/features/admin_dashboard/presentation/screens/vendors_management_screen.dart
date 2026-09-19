import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/admin_providers.dart';

class VendorsManagementScreen extends ConsumerStatefulWidget {
  const VendorsManagementScreen({super.key});

  @override
  ConsumerState<VendorsManagementScreen> createState() =>
      _VendorsManagementScreenState();
}

class _VendorsManagementScreenState
    extends ConsumerState<VendorsManagementScreen> {
  String _query = '';
  String _statusFilter = 'all'; // all, approved, pending

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(allVendorsProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'إدارة الموردين',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              SizedBox(
                width: 300,
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'ابحث عن مورد...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Status Filters
          Row(
            children: [
              _filterChip('الكل', 'all'),
              const SizedBox(width: 8),
              _filterChip('معتمد', 'approved'),
              const SizedBox(width: 8),
              _filterChip('قيد المراجعة', 'pending'),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('خطأ: $e')),
              data: (vendors) {
                final filtered = vendors.where((v) {
                  final approved = v['is_approved'] == true;

                  final matchesQuery = _query.isEmpty ||
                      (v['store_name'] as String? ?? '')
                          .toLowerCase()
                          .contains(_query.toLowerCase()) ||
                      (v['profiles']?['full_name'] as String? ?? '')
                          .toLowerCase()
                          .contains(_query.toLowerCase());

                  final matchesStatus = _statusFilter == 'all' ||
                      (_statusFilter == 'approved' && approved) ||
                      (_statusFilter == 'pending' && !approved);

                  return matchesQuery && matchesStatus;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('لا يوجد موردون مطابقون'));
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(allVendorsProvider),
                  child: Card(
                    child: SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            AppColors.primaryNavy.withValues(alpha: 0.05),
                          ),
                          columns: const [
                            DataColumn(label: Text('المورد')),
                            DataColumn(label: Text('المالك')),
                            DataColumn(label: Text('الهاتف')),
                            DataColumn(label: Text('الحالة')),
                            DataColumn(label: Text('إجراءات')),
                          ],
                          rows: filtered.map((v) {
                            final approved = v['is_approved'] == true;
                            return DataRow(
                              cells: [
                                DataCell(Text(v['store_name'] ?? '')),
                                DataCell(Text(
                                  v['profiles']?['full_name'] ?? '—',
                                )),
                                DataCell(Text(
                                  v['profiles']?['phone'] ?? '—',
                                )),
                                DataCell(Chip(
                                  label: Text(
                                    approved
                                        ? 'معتمد'
                                        : 'قيد المراجعة',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor: approved
                                      ? Colors.green[100]
                                      : Colors.orange[100],
                                )),
                                DataCell(Row(
                                  children: [
                                    if (!approved)
                                      IconButton(
                                        tooltip: 'موافقة',
                                        icon: const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        ),
                                        onPressed: () => ref
                                            .read(approveVendorProvider)(
                                          v['id'],
                                          true,
                                        ),
                                      ),
                                    IconButton(
                                      tooltip: approved
                                          ? 'إلغاء الاعتماد'
                                          : 'رفض',
                                      icon: Icon(
                                        approved
                                            ? Icons.block
                                            : Icons.cancel,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => ref
                                          .read(approveVendorProvider)(
                                        v['id'],
                                        false,
                                      ),
                                    ),
                                  ],
                                )),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _statusFilter == value,
      onSelected: (_) => setState(() => _statusFilter = value),
    );
  }
}