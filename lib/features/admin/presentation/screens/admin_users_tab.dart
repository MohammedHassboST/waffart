import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';

class AdminUsersTab extends ConsumerWidget {
  const AdminUsersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = [
      {'name': 'أحمد محمد', 'phone': '0501234567', 'role': 'customer'},
      {'name': 'فاطمة علي', 'phone': '0507654321', 'role': 'customer'},
      {'name': 'متجر السلام', 'phone': '0501112223', 'role': 'vendor'},
      {'name': 'خالد سعيد', 'phone': '0503334445', 'role': 'admin'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('المستخدمون'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: users.length,
        itemBuilder: (context, i) {
          final u = users[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                _roleColor(u['role']!).withValues(alpha: 0.15),
                child: Icon(
                  _roleIcon(u['role']!),
                  color: _roleColor(u['role']!),
                ),
              ),
              title: Text(u['name']!),
              subtitle: Text(u['phone']!),
              trailing: Chip(
                label: Text(
                  _roleLabel(u['role']!),
                  style: const TextStyle(fontSize: 11),
                ),
                backgroundColor:
                _roleColor(u['role']!).withValues(alpha: 0.15),
              ),
            ),
          );
        },
      ),
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