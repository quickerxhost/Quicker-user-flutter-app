import 'banner_model.dart';
import 'category_model.dart';
import 'delivery_hub_model.dart';
import 'product_model.dart';

class HomeFeedModel {
  final String greetingName;
  final DeliveryHubModel hub;
  final List<CategoryModel> categories;
  final List<BannerModel> banners;
  final List<ProductModel> trendingProducts;

  const HomeFeedModel({
    required this.greetingName,
    required this.hub,
    required this.categories,
    required this.banners,
    required this.trendingProducts,
  });
}
