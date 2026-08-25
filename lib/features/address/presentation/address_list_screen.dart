import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/address_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/state_views.dart';
import '../application/address_controller.dart';

/// No Stitch design exists for this screen — built to match the app's
/// token system per the PRD's Address Management spec: address list, add,
/// edit, delete, default address, current-location detect (GPS -> reverse
/// geocode via [AddressRepository.reverseGeocode]).
class AddressListScreen extends ConsumerWidget {
  const AddressListScreen({super.key, this.selectionMode = false});

  /// When opened from Checkout, tapping a card selects it and pops back
  /// instead of just showing the list.
  final bool selectionMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressListControllerProvider);
    final selectedId = ref.watch(selectedAddressIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Addresses')),
      body: addressesAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => AppErrorView(message: error.toString(), onRetry: () => ref.invalidate(addressListControllerProvider)),
        data: (addresses) {
          if (addresses.isEmpty) {
            return EmptyView(
              icon: Icons.location_off_outlined,
              title: 'No saved addresses',
              message: 'Add a delivery address to speed up checkout.',
              action: ElevatedButton(onPressed: () => context.push(RoutePaths.addAddress), child: const Text('Add Address')),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.marginMobile, AppSpacing.md, AppSpacing.marginMobile, AppSpacing.xl),
            children: [
              const _UseCurrentLocationTile(),
              const SizedBox(height: AppSpacing.md),
              ...addresses.map((address) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AddressCard(
                      address: address,
                      selected: selectionMode ? selectedId == address.id : address.isDefault,
                      onTap: () {
                        if (selectionMode) {
                          ref.read(selectedAddressIdProvider.notifier).state = address.id;
                          ref.read(addressListControllerProvider.notifier).setDefault(address.id);
                          context.pop();
                        }
                      },
                      onEdit: () => context.push(RoutePaths.editAddress, extra: address),
                      onDelete: () => ref.read(addressListControllerProvider.notifier).delete(address.id),
                    ),
                  )),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          child: PrimaryButton(label: 'Add New Address', trailingIcon: Icons.add_rounded, onPressed: () => context.push(RoutePaths.addAddress)),
        ),
      ),
    );
  }
}

class _UseCurrentLocationTile extends ConsumerStatefulWidget {
  const _UseCurrentLocationTile();

  @override
  ConsumerState<_UseCurrentLocationTile> createState() => _UseCurrentLocationTileState();
}

class _UseCurrentLocationTileState extends ConsumerState<_UseCurrentLocationTile> {
  bool _detecting = false;

  Future<void> _detect() async {
    setState(() => _detecting = true);
    try {
      final locationService = ref.read(locationServiceProvider);
      final permission = await locationService.checkAndRequest();
      if (permission.name != 'granted') {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission is required.')));
        return;
      }
      final position = await locationService.getCurrentPosition();
      final address = await ref.read(addressRepositoryProvider).reverseGeocode(latitude: position.latitude, longitude: position.longitude);
      if (mounted) context.push(RoutePaths.addAddress, extra: address);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not detect your location.')));
    } finally {
      if (mounted) setState(() => _detecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _detecting ? null : _detect,
      icon: _detecting
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.my_location_rounded, color: AppColors.primary),
      label: const Text('Use Current Location'),
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), alignment: Alignment.centerLeft),
    );
  }
}
