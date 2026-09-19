import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/admin_providers.dart';

class OrdersManagementScreen extends ConsumerStatefulWidget {
  const OrdersManagementScreen({super.key});

  @override
  ConsumerState<OrdersManagementScreen> createState() =>
      _OrdersManagementScreenState();
}

class _OrdersManagementScreenState
    extends ConsumerState<OrdersManagementScreen> {
  String _query = '';
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(allOrdersProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'إدارة الطلبات',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              SizedBox(
                width: 300,
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'ابحث برقم الطلب أو اسم العميل...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Status Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('الكل', 'all'),
                const SizedBox(width: 8),
                _filterChip('قيد الانتظار', 'pending'),
                const SizedBox(width: 8),
                _filterChip('مؤكد', 'confirmed'),
                const SizedBox(width: 8),
                _filterChip('تم الشحن', 'shipped'),
                const SizedBox(width: 8),
                _filterChip('تم التسليم', 'delivered'),
                const SizedBox(width: 8),
                _filterChip('ملغي', 'cancelled'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('خطأ: $e')),
              data: (orders) {
                final filtered = orders.where((o) {
                  final matchesQuery = _query.isEmpty ||
                      (o['order_number'] as String? ?? '')
                          .toLowerCase()
                          .contains(_query.toLowerCase()) ||
                      (o['profiles']?['full_name'] as String? ?? '')
                          .toLowerCase()
                          .contains(_query.toLowerCase());
                  final matchesStatus = _statusFilter == 'all' ||
                      o['status'] == _statusFilter;
                  return matchesQuery && matchesStatus;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('لا توجد طلبات مطابقة'));
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(allOrdersProvider),
                  child: Card(
                    child: SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            AppColors.primaryNavy.withValues(alpha: 0.05),
                          ),
                          columns: const [
                            DataColumn(label: Text('رقم الطلب')),
                            DataColumn(label: Text('العميل')),
                            DataColumn(label: Text('الهاتف')),
                            DataColumn(label: Text('الإجمالي')),
                            DataColumn(label: Text('الحالة')),
                            DataColumn(label: Text('التاريخ')),
                          ],
                          rows: filtered.map((o) {
                            return DataRow(
                              cells: [
                                DataCell(Text(o['order_number'] ?? '')),
                                DataCell(Text(
                                  o['profiles']?['full_name'] ?? '—',
                                )),
                                DataCell(Text(
                                  o['profiles']?['phone'] ?? '—',
                                )),
                                DataCell(Text(Formatters.currency(
                                  (o['total_amount'] as num)
                                      .toDouble(),
                                ))),
                                DataCell(Chip(
                                  label: Text(
                                    _statusLabel(o['status']),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor:
                                  _statusColor(o['status']),
                                )),
                                DataCell(Text(Formatters.dateTime(
                                  DateTime.parse(o['created_at']),
                                ))),
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

  String _statusLabel(String? s) {
    switch (s) {
      case 'pending':
        return 'قيد الانتظار';
      case 'confirmed':
        return 'مؤكد';
      case 'processing':
        return 'قيد التجهيز';
      case 'shipped':
        return 'تم الشحن';
      case 'delivered':
        return 'تم التسليم';
      case 'cancelled':
        return 'ملغي';
      default:
        return s ?? '';
    }
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'pending':
        return Colors.orange[100]!;
      case 'confirmed':
        return Colors.blue[100]!;
      case 'processing':
        return Colors.indigo[100]!;
      case 'shipped':
        return Colors.purple[100]!;
      case 'delivered':
        return Colors.green[100]!;
      case 'cancelled':
        return Colors.red[100]!;
      default:
        return Colors.grey[200]!;
    }
  }
}