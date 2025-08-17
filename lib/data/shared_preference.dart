// --- STORAGE SERVICE ---
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:products/models/category.dart';
import 'package:products/models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductStorageService {
  static const _storageKey = 'product_categories';

  static List<Category> getInitialCategories() => [
    Category(
      name: 'Dairy Products',
      icon: Icons.icecream,
      color: Colors.blue.shade400,
      products: [],
    ),
    Category(
      name: 'Bakery Goods',
      icon: Icons.bakery_dining,
      color: Colors.orange.shade400,
      products: [],
    ),
    Category(
      name: 'Fresh Produce',
      icon: Icons.local_florist,
      color: Colors.green.shade500,
      products: [],
    ),
    Category(
      name: 'Meat & Poultry',
      icon: Icons.set_meal,
      color: Colors.red.shade400,
      products: [],
    ),
    Category(
      name: 'Pantry Staples',
      icon: Icons.store,
      color: Colors.brown.shade400,
      products: [],
    ),
    Category(
      name: 'Frozen Foods',
      icon: Icons.ac_unit,
      color: Colors.cyan.shade400,
      products: [],
    ),
  ];

  Future<void> saveCategories(List<Category> categories) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(
      categories.map((c) => c.toJson()).toList(),
    );
    await prefs.setString(_storageKey, encodedData);
  }

  Future<List<Category>> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString(_storageKey);
    final staticCategories = getInitialCategories();

    if (encodedData == null) return staticCategories;

    final List<dynamic> decodedData = jsonDecode(encodedData);
    final Map<String, List<Product>> savedProductsMap = {
      for (var catData in decodedData)
        catData['name']:
            (catData['products'] as List)
                .map((p) => Product.fromJson(p))
                .toList(),
    };

    return staticCategories
        .map(
          (staticCat) => Category(
            name: staticCat.name,
            icon: staticCat.icon,
            color: staticCat.color,
            products: savedProductsMap[staticCat.name] ?? [],
          ),
        )
        .toList();
  }
}
