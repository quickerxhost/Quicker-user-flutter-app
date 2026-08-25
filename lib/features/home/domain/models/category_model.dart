import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final IconData icon;
  final String? imageUrl;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    this.imageUrl,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      icon: Icons.category_outlined,
      imageUrl: json['image_url'] as String?,
    );
  }
}
