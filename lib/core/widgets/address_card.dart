import 'package:flutter/material.dart';
import '../../features/address/domain/models/address_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AddressCard extends StatelessWidget {
  const AddressCard({
    super.key,
    required this.address,
    this.selected = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
  });

  final AddressModel address;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  IconData get _typeIcon => switch (address.type) {
        AddressType.home => Icons.home_rounded,
        AddressType.office => Icons.business_rounded,
        AddressType.other => Icons.location_on_rounded,
      };

  String get _typeLabel => switch (address.type) {
        AddressType.home => 'Home',
        AddressType.office => 'Office',
        AddressType.other => 'Other',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: AppColors.primaryFixed, shape: BoxShape.circle),
              child: Icon(_typeIcon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(_typeLabel, style: AppTypography.bodyMd().copyWith(fontWeight: FontWeight.w700)),
                      if (address.isDefault) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.primaryFixed, borderRadius: BorderRadius.circular(AppRadius.sm)),
                          child: Text('DEFAULT', style: AppTypography.labelLg(color: AppColors.primary).copyWith(fontSize: 10)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(address.fullLine, style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            if (showActions)
              Column(
                children: [
                  if (onEdit != null) IconButton(iconSize: 18, onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
                  if (onDelete != null) IconButton(iconSize: 18, onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
