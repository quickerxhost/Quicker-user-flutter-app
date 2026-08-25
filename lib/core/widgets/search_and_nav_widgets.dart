import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// Pill search bar reused on Home ("search" + "mic" + "qr_code_scanner")
/// and the Search screen header.
class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    this.controller,
    this.hintText = 'Search for products, stores...',
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.onVoiceTap,
    this.onScanTap,
    this.readOnly = false,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String hintText;
  final VoidCallback? onTap;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onVoiceTap;
  final VoidCallback? onScanTap;
  final bool readOnly;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search, color: AppColors.onSurfaceVariant, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onTap: onTap,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              readOnly: readOnly,
              autofocus: autofocus,
              style: AppTypography.bodyMd(),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTypography.bodyMd(color: AppColors.outline),
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (onVoiceTap != null)
            IconButton(
              onPressed: onVoiceTap,
              icon: const Icon(Icons.mic_none_rounded, color: AppColors.primary),
            ),
          if (onScanTap != null)
            IconButton(
              onPressed: onScanTap,
              icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
            ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

/// Bottom navigation: Home / Search / Orders / Profile, per every home &
/// search screen footer in the Stitch export.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search_outlined), activeIcon: Icon(Icons.search_rounded), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), activeIcon: Icon(Icons.shopping_bag_rounded), label: 'Orders'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profile'),
      ],
    );
  }
}
