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
              const Text('إدارة الموردين',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
          const SizedBox(height: 16),
          Expanded(
            child: async.when(
              loading: () =>
              const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('خطأ: $e')),
              data: (vendors) {
                final filtered = _query.isEmpty
                    ? vendors
                    : vendors
                    .where((v) => (v['store_name'] as String)
                    .toLowerCase()
                    .contains(_query.toLowerCase()))
                    .toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('لا يوجد موردين'));
                }

                return Card(
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                          AppColors.primaryNavy.withValues(alpha: 0.05)),
                      columns: const [
                        DataColumn(label: Text('المورد')),
                        DataColumn(label: Text('المالك')),
                        DataColumn(label: Text('الهاتف')),
                        DataColumn(label: Text('الحالة')),
                        DataColumn(label: Text('إجراءات')),
                      ],
                      rows: filtered.map((v) {
                        final approved = v['is_approved'] == true;
                        return DataRow(cells: [
                          DataCell(Text(v['store_name'] ?? '')),
                          DataCell(Text(
                              v['profiles']?['full_name'] ?? '')),
                          DataCell(Text(v['profiles']?['phone'] ?? '')),
                          DataCell(Chip(
                            label: Text(approved ? 'معتمد' : 'قيد المراجعة'),
                            backgroundColor: approved
                                ? Colors.green[100]
                                : Colors.orange[100],
                          )),
                          DataCell(Row(
                            children: [
                              if (!approved)
                                IconButton(
                                  icon: const Icon(Icons.check,
                                      color: Colors.green),
                                  onPressed: () => ref
                                      .read(approveVendorProvider)(
                                      v['id'], true),
                                ),
                              IconButton(
                                icon: const Icon(Icons.block,
                                    color: Colors.red),
                                onPressed: () => ref
                                    .read(approveVendorProvider)(
                                    v['id'], false),
                              ),
                            ],
                          )),
                        ]);
                      }).toList(),
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
}