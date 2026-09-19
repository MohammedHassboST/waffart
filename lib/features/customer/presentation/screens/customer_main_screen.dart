import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../offers_feed/presentation/screens/offers_feed_screen.dart';
import '../../../orders/presentation/screens/my_orders_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class CustomerMainScreen extends ConsumerStatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  ConsumerState<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends ConsumerState<CustomerMainScreen> {
  int _index = 0;

  final _pages = const [
    OffersFeedScreen(),
    CartScreen(),
    MyOrdersScreen(),
    ProfileScreen(),
  ];

  final _labels = const ['الرئيسية', 'السلة', 'طلباتي', 'حسابي'];
  final _icons = const [
    Icons.home_outlined,
    Icons.shopping_cart_outlined,
    Icons.receipt_long_outlined,
    Icons.person_outline,
  ];
  final _activeIcons = const [
    Icons.home,
    Icons.shopping_cart,
    Icons.receipt_long,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: List.generate(4, (i) {
          return NavigationDestination(
            icon: Icon(_icons[i]),
            selectedIcon: Icon(_activeIcons[i], color: AppColors.primaryNavy),
            label: _labels[i],
          );
        }),
      ),
    );
  }
}