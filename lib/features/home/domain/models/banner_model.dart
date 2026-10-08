class BannerModel {
  final String id;
  final String title;
  final String subtitle;
  final String? code;
  final String imageUrl;
  final String? deepLink;

  const BannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    this.code,
    required this.imageUrl,
    this.deepLink,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      code: json['code'] as String?,
      imageUrl: json['image_url'] as String? ?? '',
      deepLink: json['deep_link'] as String?,
    );
  }
}
