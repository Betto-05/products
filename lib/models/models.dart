// lib/models/models.dart
import 'package:flutter/material.dart';

class Product {
  final String id;
  String name;
  int quantity;
  DateTime expiryDate;
  Product({
    required this.id,
    required this.name,
    required this.quantity,
    required this.expiryDate,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'expiryDate': expiryDate.toIso8601String(),
  };
  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'],
    name: json['name'],
    quantity: json['quantity'],
    expiryDate: DateTime.parse(json['expiryDate']),
  );
}

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
}

class ShoppingListItem {
  final String id;
  String name;
  bool isChecked;
  ShoppingListItem({
    required this.id,
    required this.name,
    this.isChecked = false,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isChecked': isChecked,
  };
  factory ShoppingListItem.fromJson(Map<String, dynamic> json) =>
      ShoppingListItem(
        id: json['id'],
        name: json['name'],
        isChecked: json['isChecked'],
      );
}
