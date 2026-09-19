import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_providers.dart';

class AdminUsersTab extends ConsumerStatefulWidget {
  const AdminUsersTab({super.key});

  @override
  ConsumerState<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends ConsumerState<AdminUsersTab> {
  String _query = '';
  String _roleFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(allUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المستخدمون'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search + Filter
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'ابحث بالاسم أو الهاتف...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('الكل', 'all'),
                      const SizedBox(width: 8),
                      _filterChip('العملاء', 'customer'),
                      const SizedBox(width: 8),
                      _filterChip('الموردون', 'vendor'),
                      const SizedBox(width: 8),
                      _filterChip('المديرون', 'admin'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              loading: () =>
              const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('خطأ: $e')),
              data: (users) {
                final filtered = users.where((u) {
                  final matchesQuery = _query.isEmpty ||
                      (u['full_name'] as String? ?? '')
                          .toLowerCase()
                          .contains(_query.toLowerCase()) ||
                      (u['phone'] as String? ?? '').contains(_query);
                  final matchesRole = _roleFilter == 'all' ||
                      u['role'] == _roleFilter;
                  return matchesQuery && matchesRole;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('لا يوجد مستخدمون'));
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(allUsersProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final u = filtered[i];
                      final role = u['role'] as String? ?? 'customer';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                            _roleColor(role).withValues(alpha: 0.15),
                            child: Icon(_roleIcon(role), color: _roleColor(role)),
                          ),
                          title: Text(u['full_name'] ?? 'بدون اسم'),
                          subtitle: Text(u['phone'] ?? ''),
                          trailing: PopupMenuButton<String>(
                            child: Chip(
                              label: Text(
                                _roleLabel(role),
                                style: const TextStyle(fontSize: 11),
                              ),
                              backgroundColor:
                              _roleColor(role).withValues(alpha: 0.15),
                            ),
                            onSelected: (newRole) async {
                              await ref
                                  .read(updateUserRoleProvider)(u['id'], newRole);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'تم تحديث الدور إلى ${_roleLabel(newRole)}'),
                                  ),
                                );
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                  value: 'customer', child: Text('عميل')),
                              const PopupMenuItem(
                                  value: 'vendor', child: Text('مورد')),
                              const PopupMenuItem(
                                  value: 'admin', child: Text('مدير')),
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

  Widget _filterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _roleFilter == value,
      onSelected: (_) => setState(() => _roleFilter = value),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'vendor':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'vendor':
        return Icons.store;
      default:
        return Icons.person;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'مدير';
      case 'vendor':
        return 'مورد';
      default:
        return 'عميل';
    }
  }
}