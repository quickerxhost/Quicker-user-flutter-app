import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../restaurant_menu/application/restaurant_menu_controller.dart';
import '../../restaurant_menu/domain/models/food_item_model.dart';

final foodDetailProvider = FutureProvider.family<FoodItemModel, String>((ref, foodId) async {
  final result = await ref.watch(menuRepositoryProvider).getFoodDetail(foodId);
  return result.when(success: (v) => v, failure: (e) => throw e);
});

final foodQuantityProvider = StateProvider.family<int, String>((ref, foodId) => 1);

/// Selected add-on option ids per group, keyed by groupId. Single-select
/// groups (e.g. spice level) keep exactly one entry; multi-select groups
/// (e.g. extra toppings) behave as a checkbox set.
final selectedAddOnsControllerProvider =
    StateNotifierProvider.family<SelectedAddOnsController, Map<String, Set<String>>, String>(
  (ref, foodId) => SelectedAddOnsController(),
);

class SelectedAddOnsController extends StateNotifier<Map<String, Set<String>>> {
  SelectedAddOnsController() : super(const {});

  void selectSingle(String groupId, String optionId) {
    state = {...state, groupId: {optionId}};
  }

  void toggleMulti(String groupId, String optionId) {
    final groupSet = {...(state[groupId] ?? const <String>{})};
    groupSet.contains(optionId) ? groupSet.remove(optionId) : groupSet.add(optionId);
    state = {...state, groupId: groupSet};
  }

  bool isSelected(String groupId, String optionId) => (state[groupId] ?? const <String>{}).contains(optionId);
}

/// Pure helpers for turning a selection map into billing data — kept
/// outside any provider since they're stateless computations.
abstract final class FoodCustomizationCalculator {
  static double addOnsTotal(FoodItemModel food, Map<String, Set<String>> selections) {
    double total = 0;
    for (final group in food.addOnGroups) {
      final selected = selections[group.id] ?? const {};
      for (final option in group.options) {
        if (selected.contains(option.id)) total += option.price;
      }
    }
    return total;
  }

  static List<String> selectedLabels(FoodItemModel food, Map<String, Set<String>> selections) {
    final labels = <String>[];
    for (final group in food.addOnGroups) {
      final selected = selections[group.id] ?? const {};
      for (final option in group.options) {
        if (selected.contains(option.id)) labels.add(option.label);
      }
    }
    return labels;
  }
}
