import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/locale/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
// final user = ref.read(authControllerProvider).valueOrNull;
// final user = ref.watch(currentUserProvider);
import '../../../auth/presentation/providers/auth_provider.dart';
import 'advanced_analytics_screen.dart';
import 'vendors_management_screen.dart';
import 'orders_management_screen.dart';

class AdminWebLayout extends ConsumerStatefulWidget {
  const AdminWebLayout({super.key});

  @override
  ConsumerState<AdminWebLayout> createState() => _AdminWebLayoutState();
}

class _AdminWebLayoutState extends ConsumerState<AdminWebLayout> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = const [
    _NavItem('نظرة عامة', Icons.dashboard, 'overview'),
    _NavItem('التحليلات', Icons.analytics, 'analytics'),
    _NavItem('الموردين', Icons.store, 'vendors'),
    _NavItem('الطلبات', Icons.receipt_long, 'orders'),
  ];

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 1:
        return const AdvancedAnalyticsScreen();
      case 2:
        return const VendorsManagementScreen();
      case 3:
        return const OrdersManagementScreen();
      default:
        return const AdvancedAnalyticsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 240,
            color: AppColors.primaryNavy,
            child: Column(
              children: [
                // Logo
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.storefront,
                            color: AppColors.primaryNavy),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Waffart Admin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),

                // Nav items
                ..._navItems.asMap().entries.map((e) {
                  final selected = _selectedIndex == e.key;
                  return Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: InkWell(
                      onTap: () => setState(() => _selectedIndex = e.key),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.accentGold.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: selected
                              ? const Border(
                            right: BorderSide(
                                color: AppColors.accentGold, width: 3),
                          )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              e.value.icon,
                              color: selected
                                  ? AppColors.accentGold
                                  : Colors.white70,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              e.value.label,
                              style: TextStyle(
                                color: selected
                                    ? AppColors.accentGold
                                    : Colors.white70,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const Spacer(),

                // Language
                ListTile(
                  leading: const Icon(Icons.language, color: Colors.white70),
                  title: Text(l10n!.language,
                      style: const TextStyle(color: Colors.white70)),
                  trailing: DropdownButton<String>(
                    value: ref.watch(localeProvider).languageCode,
                    dropdownColor: AppColors.primaryNavy,
                    underline: const SizedBox.shrink(),
                    style: const TextStyle(color: Colors.white),
                    items: [
                      DropdownMenuItem(value: 'ar', child: Text(l10n!.arabic)),
                      DropdownMenuItem(value: 'en', child: Text(l10n!.english)),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        ref
                            .read(localeProvider.notifier)
                            .setLocale(Locale(v));
                      }
                    },
                  ),
                ),
                // Logout
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text('تسجيل الخروج',
                      style: TextStyle(color: Colors.redAccent)),
                  onTap: () =>
                      ref.read(authControllerProvider.notifier).signOut(),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  height: 64,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        _navItems[_selectedIndex].label,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {},
                      ),
                      const CircleAvatar(
                        backgroundColor: AppColors.accentGold,
                        child: Icon(Icons.person, color: AppColors.primaryNavy),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String route;
  const _NavItem(this.label, this.icon, this.route);
}