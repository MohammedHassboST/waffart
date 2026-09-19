import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../widgets/admin_home_tab.dart';
import '../widgets/admin_users_tab.dart';
import '../widgets/admin_vendors_tab.dart';

class AdminMobileLayout extends ConsumerStatefulWidget {
  const AdminMobileLayout({super.key});

  @override
  ConsumerState<AdminMobileLayout> createState() => _AdminMobileLayoutState();
}

class _AdminMobileLayoutState extends ConsumerState<AdminMobileLayout> {
  int _index = 0;

  final _pages = const [
    AdminHomeTab(),
    AdminUsersTab(),
    AdminVendorsTab(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.primaryNavy),
            label: 'نظرة عامة',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: AppColors.primaryNavy),
            label: 'المستخدمون',
          ),
          NavigationDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store, color: AppColors.primaryNavy),
            label: 'الموردون',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primaryNavy),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }
}