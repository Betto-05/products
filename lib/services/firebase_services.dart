// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:products/models/models.dart';

class FirebaseService {
  final _firestore = FirebaseFirestore.instance;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  static List<Category> getInitialCategories() => [
    Category(
      name: 'Dairy',
      icon: Icons.icecream,
      color: Colors.blue.shade400,
      products: [],
    ),
    Category(
      name: 'Bakery',
      icon: Icons.bakery_dining,
      color: Colors.orange.shade400,
      products: [],
    ),
    Category(
      name: 'Produce',
      icon: Icons.local_florist,
      color: Colors.green.shade500,
      products: [],
    ),
    Category(
      name: 'Meat',
      icon: Icons.set_meal,
      color: Colors.red.shade400,
      products: [],
    ),
    Category(
      name: 'Pantry',
      icon: Icons.store,
      color: Colors.brown.shade400,
      products: [],
    ),
    Category(
      name: 'Frozen',
      icon: Icons.ac_unit,
      color: Colors.cyan.shade400,
      products: [],
    ),
  ];

  Future<List<Category>> loadCategoriesWithProducts() async {
    final userId = _userId;
    if (userId == null) return getInitialCategories();

    final staticCategories = getInitialCategories();
    final List<Category> loadedCategories = [];

    for (var staticCategory in staticCategories) {
      final productSnapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('categories')
              .doc(staticCategory.name)
              .collection('products')
              .get();
      final products =
          productSnapshot.docs
              .map((doc) => Product.fromJson(doc.data()))
              .toList();
      loadedCategories.add(
        Category(
          name: staticCategory.name,
          icon: staticCategory.icon,
          color: staticCategory.color,
          products: products,
        ),
      );
    }
    return loadedCategories;
  }

  Future<void> saveProduct(String categoryName, Product product) async {
    final userId = _userId;
    if (userId == null) return;
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(categoryName)
        .collection('products')
        .doc(product.id)
        .set(product.toJson());
  }

  Future<void> deleteProduct(String categoryName, String productId) async {
    final userId = _userId;
    if (userId == null) return;
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(categoryName)
        .collection('products')
        .doc(productId)
        .delete();
  }

  Future<void> clearAllProducts() async {
    final userId = _userId;
    if (userId == null) return;

    final staticCategories = getInitialCategories();
    final batch = _firestore.batch();
    for (var category in staticCategories) {
      var snapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('categories')
              .doc(category.name)
              .collection('products')
              .get();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
    }
    await batch.commit();
  }
}
