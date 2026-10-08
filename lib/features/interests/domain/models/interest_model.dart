import 'package:flutter/material.dart';

class InterestModel {
  final String id;
  final String label;
  final IconData icon;
  const InterestModel({required this.id, required this.label, required this.icon});
}

/// Interests catalogue — the Stitch export doesn't include a dedicated
/// design for this screen, so the list/icons here follow the exact set the
/// PRD specifies (Grocery, Vegetables, Bakery, Fashion, Electronics,
/// Restaurant, Sports, Books, Cosmetics) styled with the shared design
/// tokens/CategoryCard component used elsewhere in the app.
const kInterestCatalogue = <InterestModel>[
  InterestModel(id: 'grocery', label: 'Grocery', icon: Icons.local_grocery_store_outlined),
  InterestModel(id: 'vegetables', label: 'Vegetables', icon: Icons.eco_outlined),
  InterestModel(id: 'bakery', label: 'Bakery', icon: Icons.bakery_dining_outlined),
  InterestModel(id: 'fashion', label: 'Fashion', icon: Icons.checkroom_outlined),
  InterestModel(id: 'electronics', label: 'Electronics', icon: Icons.devices_outlined),
  InterestModel(id: 'restaurant', label: 'Restaurant', icon: Icons.restaurant_outlined),
  InterestModel(id: 'sports', label: 'Sports', icon: Icons.sports_basketball_outlined),
  InterestModel(id: 'books', label: 'Books', icon: Icons.menu_book_outlined),
  InterestModel(id: 'cosmetics', label: 'Cosmetics', icon: Icons.face_retouching_natural_outlined),
];
