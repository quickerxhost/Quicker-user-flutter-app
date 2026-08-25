import 'package:flutter/material.dart';

class OnboardingPageModel {
  final String title;
  final String description;
  final IconData heroIcon;
  final List<IconData> chipIcons;
  final List<String> chipLabels;

  const OnboardingPageModel({
    required this.title,
    required this.description,
    required this.heroIcon,
    required this.chipIcons,
    required this.chipLabels,
  });
}

/// Content lifted verbatim from Stitch `onboarding_get_started` (page 1) and
/// `onboarding_shop_local` (page 2).
const kOnboardingPages = <OnboardingPageModel>[
  OnboardingPageModel(
    title: 'Everything Near You',
    description:
        'From daily essentials to the latest tech, get anything from your favorite local stores delivered in minutes.',
    heroIcon: Icons.bolt_rounded,
    chipIcons: [
      Icons.shopping_basket_outlined,
      Icons.bakery_dining_outlined,
      Icons.checkroom_outlined,
      Icons.devices_outlined,
      Icons.egg_alt_outlined,
      Icons.edit_note_outlined,
      Icons.restaurant_outlined,
    ],
    chipLabels: ['Groceries', 'Bakery', 'Fashion', 'Electronics', 'Dairy', 'Stationery', 'Restaurants'],
  ),
  OnboardingPageModel(
    title: 'Shop Local',
    description: 'Support trusted stores near you and get items delivered in minutes.',
    heroIcon: Icons.storefront_rounded,
    chipIcons: [Icons.storefront_outlined, Icons.local_shipping_outlined],
    chipLabels: ['Fresh Produce', 'Quick Delivery'],
  ),
];
