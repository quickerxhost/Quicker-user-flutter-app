import 'package:flutter/material.dart';
import '../../features/payment/domain/models/payment_method_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class PaymentCard extends StatelessWidget {
  const PaymentCard({super.key, required this.option, required this.selected, required this.onTap});
  final PaymentMethodOption option;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon => switch (option.type) {
        PaymentType.upi => Icons.qr_code_rounded,
        PaymentType.creditCard || PaymentType.debitCard => Icons.credit_card_rounded,
        PaymentType.netBanking => Icons.account_balance_rounded,
        PaymentType.wallet => Icons.account_balance_wallet_rounded,
        PaymentType.cashOnDelivery => Icons.payments_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.base),
          border: Border.all(color: selected ? AppColors.primary : AppColors.outlineVariant, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(_icon, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.label, style: AppTypography.bodyMd().copyWith(fontWeight: FontWeight.w600)),
                  if (option.subtitle != null)
                    Text(option.subtitle!, style: AppTypography.labelLg(color: AppColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.w400)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primary : AppColors.outline,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact saved-card row for the Payment Method screen's "Saved Cards" list.
class SavedCardTile extends StatelessWidget {
  const SavedCardTile({super.key, required this.card, required this.selected, required this.onTap});
  final SavedCardModel card;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.base),
          border: Border.all(color: selected ? AppColors.primary : AppColors.outlineVariant, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.credit_card_rounded, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text('${card.network} •••• ${card.last4}', style: AppTypography.bodyMd().copyWith(fontWeight: FontWeight.w600)),
            ),
            Text('Exp ${card.expiry}', style: AppTypography.labelLg(color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
