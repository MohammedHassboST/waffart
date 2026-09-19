import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/tier_provider.dart';

class TierListWidget extends ConsumerWidget {
  final String productId;
  final int currentQuantity;
  const TierListWidget({
    super.key,
    required this.productId,
    this.currentQuantity = 1,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiersAsync = ref.watch(productTiersProvider(productId));

    return tiersAsync.when(
      loading: () => const SizedBox(
          height: 60, child: Center(child: CircularProgressIndicator())),
      error: (_, _) => const SizedBox.shrink(),
      data: (tiers) {
        if (tiers.isEmpty) return const SizedBox.shrink();

        return Card(
          color: AppColors.accentGold.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_offer_outlined,
                        color: AppColors.accentGold, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'أسعار خاصة حسب الكمية',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...tiers.map((tier) {
                  final isActive = tier.matchesQuantity(currentQuantity);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.accentGold.withOpacity(0.25)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive
                            ? AppColors.accentGold
                            : Colors.grey[300]!,
                        width: isActive ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (isActive)
                          const Icon(Icons.check_circle,
                              color: AppColors.accentGold, size: 18),
                        if (isActive) const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'من ${tier.rangeLabel} وحدة',
                            style: TextStyle(
                              fontWeight:
                              isActive ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        Text(
                          Formatters.currency(tier.pricePerUnit),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isActive
                                ? AppColors.success
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}