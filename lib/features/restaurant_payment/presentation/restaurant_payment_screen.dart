import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/payment_card.dart';
import '../../payment/application/payment_controller.dart';
import '../../payment/domain/models/payment_method_model.dart';
import '../../restaurant_cart/application/restaurant_cart_controller.dart';

/// Matches Stitch `payment_checkout`: Saved Methods (card on file), UPI
/// (Google Pay/PhonePe/Add New UPI), Credit/Debit Cards, More Options
/// (Net Banking/Wallets/COD), sticky "Confirm Order & Pay ₹X" button.
/// Reuses [selectedPaymentMethodProvider]/[kPaymentMethodOptions] from the
/// Shopping Experience's Payment feature (read-only reuse — that module
/// isn't modified) so both flows share one source of truth for payment
/// selection.
class RestaurantPaymentScreen extends ConsumerWidget {
  const RestaurantPaymentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedPaymentMethodProvider);
    final savedCardsAsync = ref.watch(savedCardsProvider);
    final cart = ref.watch(restaurantCartControllerProvider);
    final total = cart.itemTotal + 40 + 20; // delivery + packing, matches RestaurantCartBillSummary defaults

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Method')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        children: [
          Text('Saved Methods', style: AppTypography.titleLg().copyWith(fontSize: 16)),
          const SizedBox(height: AppSpacing.sm),
          savedCardsAsync.when(
            loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
            error: (_, __) => const SizedBox.shrink(),
            data: (cards) => Column(
              children: cards
                  .map((card) => SavedCardTile(
                        card: card,
                        selected: selected == PaymentType.creditCard || selected == PaymentType.debitCard,
                        onTap: () => ref.read(selectedPaymentMethodProvider.notifier).state = PaymentType.creditCard,
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('UPI', style: AppTypography.titleLg().copyWith(fontSize: 16)),
          const SizedBox(height: AppSpacing.sm),
          PaymentCard(
            option: kPaymentMethodOptions.firstWhere((o) => o.type == PaymentType.upi),
            selected: selected == PaymentType.upi,
            onTap: () => ref.read(selectedPaymentMethodProvider.notifier).state = PaymentType.upi,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('More Options', style: AppTypography.titleLg().copyWith(fontSize: 16)),
          const SizedBox(height: AppSpacing.sm),
          ...kPaymentMethodOptions
              .where((o) => o.type != PaymentType.upi && o.type != PaymentType.creditCard && o.type != PaymentType.debitCard)
              .map((option) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: PaymentCard(
                      option: option,
                      selected: selected == option.type,
                      onTap: () => ref.read(selectedPaymentMethodProvider.notifier).state = option.type,
                    ),
                  )),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full))),
              child: Text('Confirm Order & Pay ₹${total.toStringAsFixed(2)}'),
            ),
          ),
        ),
      ),
    );
  }
}
