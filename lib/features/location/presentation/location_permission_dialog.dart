import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';

enum _FetchPhase { idle, fetching, success }

/// "Fetch live location" popup shown once on first launch (right after the
/// splash → onboarding transition). Requests location permission and fetches
/// the device's live position so the home feed can show nearby shops.
Future<void> showFetchLocationDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _FetchLocationDialog(),
  );
}

class _FetchLocationDialog extends ConsumerStatefulWidget {
  const _FetchLocationDialog();

  @override
  ConsumerState<_FetchLocationDialog> createState() =>
      _FetchLocationDialogState();
}

class _FetchLocationDialogState extends ConsumerState<_FetchLocationDialog> {
  _FetchPhase _phase = _FetchPhase.idle;
  LocationPermissionState? _blockedState;
  String? _statusMessage;

  Future<void> _fetchLocation() async {
    final locationService = ref.read(locationServiceProvider);
    setState(() {
      _phase = _FetchPhase.fetching;
      _blockedState = null;
      _statusMessage = null;
    });

    final permission = await locationService.checkAndRequest();
    if (!mounted) return;

    if (permission == LocationPermissionState.granted) {
      try {
        await locationService.getCurrentPosition();
        if (!mounted) return;
        setState(() => _phase = _FetchPhase.success);
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _phase = _FetchPhase.idle;
          _statusMessage = 'Could not fetch your location. Please try again.';
        });
      }
      return;
    }

    setState(() {
      _phase = _FetchPhase.idle;
      _blockedState = permission;
      _statusMessage = _messageFor(permission);
    });
  }

  String _messageFor(LocationPermissionState permission) {
    switch (permission) {
      case LocationPermissionState.serviceDisabled:
        return 'Location services are turned off. Enable them to find shops and delivery options near you.';
      case LocationPermissionState.deniedForever:
        return 'Location permission is blocked. Open app settings to allow it and find shops near you.';
      case LocationPermissionState.denied:
        return 'Location permission is needed to show shops and delivery options near you.';
      case LocationPermissionState.granted:
        return '';
    }
  }

  Future<void> _openSystemSettings() async {
    final locationService = ref.read(locationServiceProvider);
    final opened = _blockedState == LocationPermissionState.serviceDisabled
        ? await locationService.openLocationServiceSettings()
        : await locationService.openSettings();
    if (opened && mounted) await _fetchLocation();
  }

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final isFetching = _phase == _FetchPhase.fetching;
    final isSuccess = _phase == _FetchPhase.success;
    final needsSettings =
        _blockedState == LocationPermissionState.serviceDisabled ||
            _blockedState == LocationPermissionState.deniedForever;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.primaryFixed,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess
                    ? Icons.check_rounded
                    : _blockedState != null
                        ? Icons.location_off_rounded
                        : Icons.my_location_rounded,
                color: isSuccess ? AppColors.primary : AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              isSuccess
                  ? 'Location Fetched'
                  : 'Fetch Live Location',
              style: AppTypography.headlineLgMobile(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isSuccess
                  ? 'You are all set. Shop from stores near you.'
                  : _statusMessage ??
                      'Allow QuickerX to access your location so we can show shops and delivery options near you.',
              style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: isSuccess
                  ? 'Continue'
                  : isFetching
                      ? 'Fetching Location…'
                      : needsSettings
                          ? _blockedState == LocationPermissionState.serviceDisabled
                              ? 'Enable Location Services'
                              : 'Open App Settings'
                          : 'Allow & Fetch Location',
              trailingIcon: isSuccess ? null : Icons.arrow_forward_rounded,
              isLoading: isFetching,
              onPressed: isSuccess
                  ? _close
                  : isFetching
                      ? null
                      : needsSettings
                          ? _openSystemSettings
                          : _fetchLocation,
            ),
            if (!isSuccess && !isFetching) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: _close,
                child: Text('Skip for now', style: AppTypography.labelLg(color: AppColors.onSurfaceVariant)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
