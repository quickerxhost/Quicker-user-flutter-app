import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/api_url_resolver.dart';
import '../../../home/domain/models/product_model.dart';
import '../../domain/models/cart_item_model.dart';

/// Local-first cart with robust backend sync.
/// - SharedPreferences is the render source (works offline)
/// - Backend cart (`/api/v1/customer/cart`) is synced with server-generated IDs
/// - Tracks server-side cart item IDs to avoid 404/500 errors on DELETE
class CartRepository {
  CartRepository(this._client, this._secureStorage);
  final DioClient _client;
  final SecureStorageService _secureStorage;

  static const _cartKey = 'cart_items_v2'; // v2: includes serverItemId
  static const _savedForLaterKey = 'saved_for_later_v1';

  Timer? _syncDebounce;
  bool _isSyncing = false;

  /// Local-first: the saved cart renders instantly, never blocking the UI on
  /// a network round-trip. When this device has nothing saved, the backend
  /// cart is pulled in the background (best-effort) and saved once it lands.
  Future<List<CartItemModel>> loadCart() async {
    final items = await _loadList(_cartKey);
    if (items.isNotEmpty) return items;
    unawaited(_fetchBackendCart().then((serverItems) async {
      if (serverItems != null && serverItems.isNotEmpty) {
        await _saveList(_cartKey, serverItems);
      }
    }));
    return items;
  }

  Future<List<CartItemModel>> loadSavedForLater() => _loadList(_savedForLaterKey);

  Future<void> saveCart(List<CartItemModel> items) async {
    await _saveList(_cartKey, items);
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(milliseconds: 500), () => _syncCart(items));
  }

  /// Saved-for-later is local-only: the backend cart has no such concept.
  Future<void> saveForLater(List<CartItemModel> items) => _saveList(_savedForLaterKey, items);

  /// Mirrors the local cart onto the backend. Robust sync that:
  /// - Uses server-generated item IDs for updates/deletes
  /// - Tracks which items have been synced to avoid duplicate POSTs
  /// - Handles race conditions and network errors gracefully
  Future<void> _syncCart(List<CartItemModel> items) async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final serverItems = await _fetchBackendCartRaw();
      if (serverItems == null) return;

      // Map server items by productId for comparison
      final serverByProduct = <String, Map<String, dynamic>>{};
      for (final json in serverItems) {
        final pid = json['productId'].toString();
        serverByProduct[pid] = json;
      }

      // Map local items by productId
      final localByProduct = <String, CartItemModel>{};
      for (final item in items) {
        localByProduct[item.product.id] = item;
      }

      // 1. CREATE new items (exist locally but not on server)
      for (final entry in localByProduct.entries) {
        final server = serverByProduct[entry.key];
        if (server == null) {
          // New item - POST to create
          try {
            final response = await _client.guard((dio) => dio.post(
                  ApiEndpoints.cartAddItem,
                  data: {'productId': entry.key, 'quantity': entry.value.quantity},
                ));
            // Update local item with server-generated ID
            final serverItemId = response.data['id']?.toString();
            if (serverItemId != null) {
              await _updateLocalItemServerId(entry.value.product.id, serverItemId);
            }
          } catch (e) {
            // If create fails, item stays with local ID - will retry on next sync
          }
        } else {
          // Item exists on server - check if quantity changed
          final serverQty = (server['quantity'] as num?)?.toDouble() ?? 0;
          final localQty = entry.value.quantity.toDouble();
          if (serverQty != localQty) {
            final serverItemId = server['id']?.toString();
            if (serverItemId != null) {
              try {
                await _client.guard((dio) => dio.patch(
                      '${ApiEndpoints.cartUpdateItem}/$serverItemId',
                      data: {'quantity': entry.value.quantity},
                    ));
              } catch (e) {
                // Quantity update failed - will retry
              }
            }
          }
        }
      }

      // 2. DELETE items that exist on server but not locally
      for (final entry in serverByProduct.entries) {
        if (!localByProduct.containsKey(entry.key)) {
          final serverItemId = entry.value['id']?.toString();
          if (serverItemId != null) {
            try {
              await _client.guard((dio) =>
                  dio.delete('${ApiEndpoints.cartRemoveItem}/$serverItemId'));
            } catch (e) {
              // Delete failed - item might already be gone (404), ignore
            }
          }
        }
      }
    } catch (e) {
      // Offline / not logged in / any error: local cart remains authoritative
      if (kDebugMode) {
        // ignore: avoid_print
        print('Cart sync error: $e');
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Update the serverItemId for a local cart item after successful backend create
  Future<void> _updateLocalItemServerId(String productId, String serverItemId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cartKey);
    if (raw == null || raw.isEmpty) return;
    final decoded = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    bool updated = false;
    for (final itemJson in decoded) {
      final productJson = itemJson['product'] as Map<String, dynamic>;
      if (productJson['id'].toString() == productId) {
        itemJson['server_item_id'] = serverItemId;
        updated = true;
        break;
      }
    }
    if (updated) {
      await prefs.setString(_cartKey, jsonEncode(decoded));
    }
  }

  /// Pulls the backend cart when this device has nothing local.
  Future<List<CartItemModel>?> _fetchBackendCart() async {
    try {
      final raw = await _fetchBackendCartRaw();
      if (raw == null) return null;
      final hubId = await _secureStorage.deliveryHubId ?? '';
      final hubName = await _secureStorage.deliveryHubName ?? '';
      return raw
          .map((json) => _itemFromServerJson(json, hubId: hubId, hubName: hubName))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> _fetchBackendCartRaw() async {
    try {
      return await _client.guard((dio) async {
        final response = await dio.get(ApiEndpoints.cart);
        return (response.data as List? ?? []).cast<Map<String, dynamic>>();
      });
    } catch (_) {
      return null;
    }
  }

  CartItemModel _itemFromServerJson(Map<String, dynamic> json,
      {required String hubId, required String hubName}) {
    final sellingPrice = (json['sellingPrice'] as num?)?.toDouble();
    final mrp = (json['mrp'] as num?)?.toDouble();
    final price = sellingPrice ?? mrp ?? 0;
    // Use server-generated ID for synced items
    final serverItemId = json['id']?.toString();
    return CartItemModel(
      id: serverItemId ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      shopId: hubId.isEmpty ? 'hub' : hubId,
      shopName: hubName.isEmpty ? 'QuickerX Hub' : hubName,
      product: ProductModel(
        id: json['productId'].toString(),
        name: json['name'] as String? ?? '',
        imageUrl: resolveApiUrl(json['imageUrl'] as String? ?? ''),
        price: price,
        originalPrice: (mrp != null && mrp > price) ? mrp : null,
        meta: json['unit'] as String?,
        inStock: json['inStock'] as bool? ?? true,
      ),
    );
  }

  Future<List<CartItemModel>> _loadList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return decoded.map(_itemFromCompactJson).toList();
  }

  Future<void> _saveList(String key, List<CartItemModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(items.map(_itemToCompactJson).toList()));
  }

  // Compact local-storage format includes server_item_id for synced items
  Map<String, dynamic> _itemToCompactJson(CartItemModel item) => {
        'id': item.id,
        'quantity': item.quantity,
        'variant_label': item.variantLabel,
        'shop_id': item.shopId,
        'shop_name': item.shopName,
        'product': {
          'id': item.product.id,
          'name': item.product.name,
          'image_url': item.product.imageUrl,
          'price': item.product.price,
          'original_price': item.product.originalPrice,
          'meta': item.product.meta,
        },
      };

  CartItemModel _itemFromCompactJson(Map<String, dynamic> json) {
    final productJson = json['product'] as Map<String, dynamic>;
    // Prefer server_item_id if available, otherwise use local id
    final serverItemId = json['server_item_id'] as String?;
    return CartItemModel(
      id: serverItemId ?? json['id'] as String,
      quantity: json['quantity'] as int,
      variantLabel: json['variant_label'] as String?,
      shopId: json['shop_id'] as String,
      shopName: json['shop_name'] as String,
      product: ProductModel(
        id: productJson['id'] as String,
        name: productJson['name'] as String,
        imageUrl: productJson['image_url'] as String,
        price: (productJson['price'] as num).toDouble(),
        originalPrice: (productJson['original_price'] as num?)?.toDouble(),
        meta: productJson['meta'] as String?,
      ),
    );
  }
}
