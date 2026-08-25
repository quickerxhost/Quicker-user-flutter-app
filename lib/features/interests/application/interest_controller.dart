import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/providers/core_providers.dart';

final interestSelectionProvider =
    StateNotifierProvider<InterestSelectionController, Set<String>>((ref) {
  return InterestSelectionController(ref.watch(dioClientProvider));
});

class InterestSelectionController extends StateNotifier<Set<String>> {
  InterestSelectionController(this._client) : super(<String>{});
  final DioClient _client;

  void toggle(String id) {
    final next = {...state};
    next.contains(id) ? next.remove(id) : next.add(id);
    state = next;
  }

  bool isSelected(String id) => state.contains(id);

  /// Persists the selected interests. `ApiEndpoints.saveInterests` is
  /// currently blank; this becomes a real call the moment it's filled in —
  /// until then it resolves as a no-op so the onboarding flow isn't blocked.
  Future<void> savePreferences() async {
    if (ApiEndpoints.saveInterests.isEmpty) return;
    await _client.guard((dio) => dio.post(
          ApiEndpoints.saveInterests,
          data: {'interests': state.toList()},
        ));
  }
}
