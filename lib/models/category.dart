import 'package:flutter/material.dart';
import 'package:products/models/product.dart';

class Category {
  final String name;
  final IconData icon;
  final Color color;
  final List<Product> products;

  Category({
    required this.name,
    required this.icon,
    required this.color,
    required this.products,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'products': products.map((p) => p.toJson()).toList(),
  };

  factory Category.fromJson(
    Map<String, dynamic> json,
    IconData icon,
    Color color,
  ) => Category(
    name: json['name'],
    icon: icon,
    color: color,
    products:
        (json['products'] as List).map((p) => Product.fromJson(p)).toList(),
  );
}
