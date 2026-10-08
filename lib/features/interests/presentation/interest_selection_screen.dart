import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../application/interest_controller.dart';
import '../domain/models/interest_model.dart';

/// No Stitch design exists for this screen — built to match the app's
/// design system (same radii/colors/typography/animated-chip pattern as
/// [CategoryCard]) per the PRD's "User Interest Selection" spec.
class InterestSelectionScreen extends ConsumerWidget {
  const InterestSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(interestSelectionProvider);
    final controller = ref.read(interestSelectionProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What are you shopping for?', style: AppTypography.headlineLgMobile()),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Pick a few interests so we can personalize your home feed. You can change these anytime.',
                style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: GridView.builder(
                  itemCount: kInterestCatalogue.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: AppSpacing.lg,
                    crossAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (context, index) {
                    final interest = kInterestCatalogue[index];
                    final isSelected = selected.contains(interest.id);
                    return _InterestChip(
                      interest: interest,
                      selected: isSelected,
                      onTap: () => controller.toggle(interest.id),
                    );
                  },
                ),
              ),
              Text(
                '${selected.length} selected',
                style: AppTypography.labelLg(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.sm),
              PrimaryButton(
                label: 'Continue',
                onPressed: selected.isEmpty
                    ? null
                    : () async {
                        try {
                          await controller.savePreferences();
                        } catch (_) {
                          // Best-effort: preference persistence must never
                          // block the onboarding flow.
                        }
                        if (context.mounted) context.go(RoutePaths.onboarding);
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({required this.interest, required this.selected, required this.onTap});
  final InterestModel interest;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.base),
          border: Border.all(color: selected ? AppColors.primary : AppColors.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(interest.icon, color: selected ? Colors.white : AppColors.primary, size: 28),
            const SizedBox(height: 6),
            Text(
              interest.label,
              textAlign: TextAlign.center,
              style: AppTypography.labelLg(color: selected ? Colors.white : AppColors.onSurfaceVariant)
                  .copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
