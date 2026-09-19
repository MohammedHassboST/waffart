import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final user = ref.watch(currentUserProvider); 
    final userAsync = ref.watch(currentUserProvider); // استخدام userAsync للتعامل مع AsyncValue


    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (user) {
          if (user == null) return const Center(child: Text('غير مسجل'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
              const SizedBox(height: 16),
              _InfoTile(label: 'الاسم', value: user.fullName ?? 'غير مسجل'),
              _InfoTile(label: 'الهاتف', value: user.phone ?? 'غير مسجل'),
              _InfoTile(label: 'البريد الإلكتروني', value: user.email ?? 'غير مسجل'),
              _InfoTile(label: 'الدور', value: user.role),
              if (user.businessName != null)
                _InfoTile(label: 'النشاط التجاري', value: user.businessName!),
              if (user.address != null)
                _InfoTile(label: 'العنوان', value: user.address!),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('تسجيل الخروج',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16)),
    );
  }
}