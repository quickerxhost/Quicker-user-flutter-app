import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../data/repositories/address_repository.dart';
import '../domain/models/address_model.dart';

final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  return AddressRepository(ref.watch(dioClientProvider));
});

final addressListControllerProvider =
    AsyncNotifierProvider<AddressListController, List<AddressModel>>(AddressListController.new);

class AddressListController extends AsyncNotifier<List<AddressModel>> {
  late final AddressRepository _repository;

  @override
  Future<List<AddressModel>> build() async {
    _repository = ref.read(addressRepositoryProvider);
    return _repository.loadAll();
  }

  Future<void> addOrUpdate(AddressModel address) async {
    final current = state.valueOrNull ?? [];
    final index = current.indexWhere((a) => a.id == address.id);
    List<AddressModel> updated;
    if (index >= 0) {
      updated = [...current]..[index] = address;
    } else {
      updated = [...current, address];
    }
    if (address.isDefault) {
      updated = updated.map((a) => a.id == address.id ? a : a.copyWith(isDefault: false)).toList();
    } else if (updated.length == 1) {
      updated = [updated.first.copyWith(isDefault: true)];
    }
    state = AsyncValue.data(updated);
    await _repository.saveAll(updated);
  }

  Future<void> delete(String id) async {
    final current = state.valueOrNull ?? [];
    var updated = current.where((a) => a.id != id).toList();
    if (updated.isNotEmpty && !updated.any((a) => a.isDefault)) {
      updated = [updated.first.copyWith(isDefault: true), ...updated.skip(1)];
    }
    state = AsyncValue.data(updated);
    await _repository.saveAll(updated);
  }

  Future<void> setDefault(String id) async {
    final current = state.valueOrNull ?? [];
    final updated = current.map((a) => a.copyWith(isDefault: a.id == id)).toList();
    state = AsyncValue.data(updated);
    await _repository.saveAll(updated);
  }

  AddressModel? get defaultAddress {
    final current = state.valueOrNull ?? [];
    if (current.isEmpty) return null;
    return current.firstWhere((a) => a.isDefault, orElse: () => current.first);
  }
}

/// The address selected for the current checkout session — defaults to
/// [AddressListController.defaultAddress] but can be switched per-order.
final selectedAddressIdProvider = StateProvider<String?>((ref) => null);
