import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/payment_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../application/payment_controller.dart';
import '../domain/models/payment_method_model.dart';

/// No Stitch design exists for this screen — built to match the app's
/// token system per the PRD's Payment Method spec: UPI, cards, net
/// banking, wallet, COD, saved cards, add card, secure-payment note.
class PaymentMethodScreen extends ConsumerWidget {
  const PaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedPaymentMethodProvider);
    final savedCardsAsync = ref.watch(savedCardsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Method')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        children: [
          if (selected == PaymentType.creditCard || selected == PaymentType.debitCard) ...[
            Text('Saved Cards', style: AppTypography.titleLg().copyWith(fontSize: 16)),
            const SizedBox(height: AppSpacing.sm),
            savedCardsAsync.when(
              loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (_, __) => const SizedBox.shrink(),
              data: (cards) => Column(
                children: cards.map((card) => SavedCardTile(card: card, selected: false, onTap: () {})).toList(),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Card entry goes through your payment gateway SDK (Razorpay/Stripe/etc.) — wire it in when ready.')),
              ),
              icon: const Icon(Icons.add_card_rounded),
              label: const Text('Add New Card'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), alignment: Alignment.centerLeft),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text('All Payment Options', style: AppTypography.titleLg().copyWith(fontSize: 16)),
          const SizedBox(height: AppSpacing.sm),
          ...kPaymentMethodOptions.map((option) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: PaymentCard(
                  option: option,
                  selected: selected == option.type,
                  onTap: () => ref.read(selectedPaymentMethodProvider.notifier).state = option.type,
                ),
              )),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Payments are encrypted and processed securely.', style: AppTypography.labelLg(color: AppColors.onSurfaceVariant)),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          child: PrimaryButton(label: 'Confirm Payment Method', trailingIcon: null, onPressed: () => context.pop()),
        ),
      ),
    );
  }
}
