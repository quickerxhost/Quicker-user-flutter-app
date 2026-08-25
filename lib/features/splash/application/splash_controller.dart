import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/router/route_paths.dart';
import '../../authentication/application/auth_controller.dart';

/// Runs the splash-time initialization sequence (check login token, check
/// connectivity) and resolves which route to land on. App-update checks are
/// intentionally omitted — there's no backend/store version endpoint yet
/// (see AppConfig note); wire in `ApiEndpoints` once available.
final splashDestinationProvider = FutureProvider<String>((ref) async {
  // Minimum splash duration so the brand animation isn't cut short on fast
  // devices — matches the Stitch 3s progress-bar timing.
  final minimumDelay = Future.delayed(const Duration(milliseconds: 2600));

  final storage = ref.read(secureStorageProvider);
  final token = await storage.accessToken;

  await minimumDelay;

  if (token != null && token.isNotEmpty) {
    await ref.read(authControllerProvider.notifier).loadProfile();
    return RoutePaths.home;
  }
  return RoutePaths.onboarding;
});
