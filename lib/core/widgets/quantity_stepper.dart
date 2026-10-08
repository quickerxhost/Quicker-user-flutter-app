import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// Animated +/- quantity stepper used on Product Details and Cart line
/// items. Shows an "Add" pill button when [quantity] is 0.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.compact = false,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final height = compact ? 32.0 : 40.0;

    if (quantity <= 0) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: compact ? 80 : 120),
        child: SizedBox(
          height: height,
          child: ElevatedButton(
            onPressed: onIncrement,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
              elevation: 0,
            ),
            child: const Text('ADD'),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 100 : 140),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: height,
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.full)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StepperButton(icon: Icons.remove_rounded, onTap: onDecrement),
            Flexible(
              child: Text(
                '$quantity',
                textAlign: TextAlign.center,
                style: AppTypography.labelLg(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _StepperButton(icon: Icons.add_rounded, onTap: onIncrement),
          ],
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}
