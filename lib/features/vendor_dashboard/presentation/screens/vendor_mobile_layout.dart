import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../widgets/vendor_home_tab.dart';
import '../widgets/vendor_products_tab.dart';
import '../widgets/vendor_orders_tab.dart';

class VendorMobileLayout extends ConsumerStatefulWidget {
  const VendorMobileLayout({super.key});

  @override
  ConsumerState<VendorMobileLayout> createState() =>
      _VendorMobileLayoutState();
}

class _VendorMobileLayoutState extends ConsumerState<VendorMobileLayout> {
  int _index = 0;

  final _pages = const [
    VendorHomeTab(),
    VendorProductsTab(),
    VendorOrdersTab(),
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
            label: 'لوحتي',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon:
            Icon(Icons.inventory_2, color: AppColors.primaryNavy),
            label: 'منتجاتي',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon:
            Icon(Icons.receipt_long, color: AppColors.primaryNavy),
            label: 'الطلبات',
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