import 'package:flutter/material.dart';
import '../../../core/widgets/state_views.dart';

/// Orders is out of scope for Phase 1 (Authentication + Discovery + Home) —
/// this is a minimal placeholder so the bottom nav has 4 working tabs.
/// Replace with the real Orders module in the next phase.
class OrdersPlaceholderScreen extends StatelessWidget {
  const OrdersPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: const EmptyView(
        icon: Icons.receipt_long_outlined,
        title: 'No orders yet',
        message: 'The Orders module ships in the next phase.',
      ),
    );
  }
}
