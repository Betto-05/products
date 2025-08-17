// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:products/models/models.dart';

class DashboardScreen extends StatelessWidget {
  final List<Category> categories;
  final Map<String, dynamic> settings;
  final Function(Category) onNavigateToCategory;
  const DashboardScreen({
    super.key,
    required this.categories,
    required this.settings,
    required this.onNavigateToCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildAnimatedSummaryBar(context),
          _buildExpiringSoonSection(context),
          _buildSectionHeader("All Categories"),
          _buildGridView(),
        ],
      ),
    );
  }

  Widget _buildExpiringSoonSection(BuildContext context) {
    final int expiringDays = settings['expiringSoonDays'] ?? 7;
    final now = DateTime.now();
    final expiringProducts =
        categories.expand((c) => c.products).where((p) {
            final difference = p.expiryDate.difference(now).inDays;
            return difference >= 0 && difference < expiringDays;
          }).toList()
          ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Expiring Soon (Next $expiringDays Days)"),
        if (expiringProducts.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.check_circle_outline, color: Colors.green),
              title: Text("Nothing is expiring soon!"),
            ),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: expiringProducts.length,
              itemBuilder: (context, index) {
                final product = expiringProducts[index];
                final category = categories.firstWhere(
                  (c) => c.products.contains(product),
                );
                final daysLeft = product.expiryDate.difference(now).inDays + 1;
                return SizedBox(
                  width: 160,
                  child: Card(
                    color:
                        Theme.of(context).brightness == Brightness.light
                            ? Colors.amber.shade50
                            : Colors.amber.shade900.withOpacity(0.4),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.amber.shade700,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "$daysLeft days left",
                                style: TextStyle(
                                  color: Colors.amber.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(top: 24.0, bottom: 8.0, left: 4.0),
    child: Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );

  Widget _buildGridView() => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.only(bottom: 16),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.0,
    ),
    itemCount: categories.length,
    itemBuilder: (context, index) {
      final category = categories[index];
      return Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onNavigateToCategory(category),
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
    },
  );

  Widget _buildAnimatedSummaryBar(BuildContext context) {
    final totalProducts =
        categories.isNotEmpty
            ? categories.map((c) => c.products.length).reduce((a, b) => a + b)
            : 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: IntrinsicHeight(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                context,
                '${categories.length}',
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
                context,
                '$totalProducts',
                'Total Items',
                Icons.inventory_2,
                Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color,
  ) => Column(
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
          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
        ),
      ),
    ],
  );
}
