// lib/screens/analytics_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:products/models/models.dart';

class AnalyticsScreen extends StatefulWidget {
  final List<Category> categories;
  const AnalyticsScreen({super.key, required this.categories});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final productsByCategory =
        widget.categories.where((c) => c.products.isNotEmpty).toList();
    final totalProducts = productsByCategory.fold<int>(
      0,
      (sum, cat) => sum + cat.products.length,
    );
    final mostStocked =
        productsByCategory.isEmpty
            ? 'N/A'
            : productsByCategory
                .reduce((a, b) => a.products.length > b.products.length ? a : b)
                .name;

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body:
          productsByCategory.isEmpty
              ? const Center(
                child: Text("No products to analyze. Add some first!"),
              )
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                touchedIndex = -1;
                                return;
                              }
                              touchedIndex =
                                  pieTouchResponse
                                      .touchedSection!
                                      .touchedSectionIndex;
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: showingSections(
                          productsByCategory,
                          totalProducts,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Summary",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    context,
                    "Total Items",
                    totalProducts.toString(),
                    Icons.inventory_2,
                    Theme.of(context).colorScheme.primary,
                  ),
                  _buildStatCard(
                    context,
                    "Most Stocked",
                    mostStocked,
                    Icons.star_rounded,
                    Colors.amber.shade700,
                  ),
                ],
              ),
    );
  }

  List<PieChartSectionData> showingSections(List<Category> data, int total) {
    return List.generate(data.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 16.0 : 14.0;
      final radius = isTouched ? 60.0 : 50.0;
      final percentage = (data[i].products.length / total * 100)
          .toStringAsFixed(1);
      return PieChartSectionData(
        color: data[i].color,
        value: data[i].products.length.toDouble(),
        title: '$percentage%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [const Shadow(color: Colors.black, blurRadius: 2)],
        ),
      );
    });
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) => Card(
    margin: const EdgeInsets.symmetric(vertical: 6),
    child: ListTile(
      leading: Icon(icon, color: color, size: 32),
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
        ),
      ),
      subtitle: Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
    ),
  );
}
