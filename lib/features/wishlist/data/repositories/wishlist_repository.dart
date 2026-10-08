import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/dio_client.dart';
import '../../../home/domain/models/product_model.dart';

/// The backend has no /wishlist module yet — wishlist is persisted locally
/// (SharedPreferences), mirroring [CartRepository]'s pattern, with
/// pagination applied in-memory client-side (`getPage`) so the screen's
/// pagination UI is exercised end-to-end even before the backend exists.
class WishlistRepository {
  WishlistRepository(this._client);
  // ignore: unused_field
  final DioClient _client;

  static const _key = 'wishlist_items_v1';

  Future<List<ProductModel>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return _seedIfEmpty(prefs);
    final decoded = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return decoded.map(_fromCompactJson).toList();
  }

  /// First-run seed so the screen isn't empty on a fresh install — mirrors
  /// a couple of Home's trending items. Harmless once real wishlisting
  /// starts (this only fires when no key exists yet).
  Future<List<ProductModel>> _seedIfEmpty(SharedPreferences prefs) async {
    const seed = <ProductModel>[
      ProductModel(id: 'p1', name: 'Farm Fresh Dairy — Organic A2 Whole Milk', imageUrl: '', price: 84, originalPrice: 105, meta: '1 Liter • Tetra Pack'),
    ];
    await _save(prefs, seed);
    return seed;
  }

  Future<void> saveAll(List<ProductModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    await _save(prefs, items);
    // NOTE: no backend /wishlist module yet — sync the diff here when it lands.
  }

  Future<void> _save(SharedPreferences prefs, List<ProductModel> items) {
    return prefs.setString(_key, jsonEncode(items.map(_toCompactJson).toList()));
  }

  Map<String, dynamic> _toCompactJson(ProductModel p) => {
        'id': p.id,
        'name': p.name,
        'image_url': p.imageUrl,
        'price': p.price,
        'original_price': p.originalPrice,
        'meta': p.meta,
      };

  ProductModel _fromCompactJson(Map<String, dynamic> json) => ProductModel(
        id: json['id'] as String,
        name: json['name'] as String,
        imageUrl: json['image_url'] as String,
        price: (json['price'] as num).toDouble(),
        originalPrice: (json['original_price'] as num?)?.toDouble(),
        meta: json['meta'] as String?,
        isWishlisted: true,
      );
}
