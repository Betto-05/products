// --- CATEGORY SELECTION SCREEN ---
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:products/data/shared_preference.dart';
import 'package:products/models/category.dart';
import 'package:products/screens/product_list_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});
  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final ProductStorageService _storageService = ProductStorageService();
  List<Category> _categories = [];
  bool _isLoading = true;
  bool _isContentVisible = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final loadedCategories = await _storageService.loadCategories();
    if (mounted) {
      setState(() {
        _categories = loadedCategories;
        _isLoading = false;
      });
      Timer(const Duration(milliseconds: 200), () {
        if (mounted) setState(() => _isContentVisible = true);
      });
    }
  }

  Future<void> _saveData() async {
    await _storageService.saveCategories(_categories);
    setState(() {});
  }

  void _navigateToProductList(Category category) {
    Navigator.of(context)
        .push(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder:
                (context, animation, secondaryAnimation) => ProductListScreen(
                  category: category,
                  onDataChanged: _saveData,
                ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
          ),
        )
        .then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Dashboard')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    _buildAnimatedSummaryBar(),
                    const SizedBox(height: 16),
                    Expanded(child: _buildGridView()),
                  ],
                ),
              ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return AnimatedOpacity(
          opacity: _isContentVisible ? 1.0 : 0.0,
          duration: Duration(milliseconds: 400 + (index * 100)),
          curve: Curves.easeOut,
          child: AnimatedSlide(
            offset: _isContentVisible ? Offset.zero : const Offset(0, 0.3),
            duration: Duration(milliseconds: 400 + (index * 100)),
            curve: Curves.easeOut,
            child: _buildCategoryCard(category),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedSummaryBar() {
    final totalProducts =
        _categories.isNotEmpty
            ? _categories.map((c) => c.products.length).reduce((a, b) => a + b)
            : 0;

    return AnimatedOpacity(
      opacity: _isContentVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _isContentVisible ? Offset.zero : const Offset(0, -0.5),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                    '${_categories.length}',
                    'Categories',
                    Icons.category,
                    Colors.purple.shade300,
                  ),
                  VerticalDivider(
                    color: Colors.grey.shade300,
                    thickness: 1,
                    indent: 8,
                    endIndent: 8,
                  ),
                  _buildSummaryItem(
                    '$totalProducts',
                    'Total Products',
                    Icons.inventory_2,
                    Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(
              context,
            ).textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(Category category) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToProductList(category),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(category.icon, size: 32, color: category.color),
              ),
              const SizedBox(height: 12),
              Text(
                category.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                '${category.products.length} items',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
