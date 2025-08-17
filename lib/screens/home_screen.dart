// lib/screens/home_page.dart
import 'package:flutter/material.dart';
import 'package:products/models/models.dart';
import 'package:products/providers/theme_notifier.dart';
import 'package:products/screens/analytics_screen.dart';
import 'package:products/screens/dashboard_screen.dart';
import 'package:products/screens/product_list_screen.dart';
import 'package:products/screens/settings_screen.dart';
import 'package:products/screens/shopping_list_screen.dart';
import 'package:products/services/firebase_services.dart';
import 'package:products/services/storage_services.dart';

class HomePage extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const HomePage({super.key, required this.themeNotifier});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final FirebaseService _firebaseService = FirebaseService();
  final StorageService _storageService = StorageService();
  List<Category> _categories = [];
  Map<String, dynamic> _settings = {'expiringSoonDays': 7};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    final loadedCategories =
        await _firebaseService.loadCategoriesWithProducts();
    final loadedSettings = await _storageService.loadSettings();
    if (mounted) {
      setState(() {
        _categories = loadedCategories;
        _settings = loadedSettings;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings(Map<String, dynamic> newSettings) async {
    await _storageService.saveSettings(newSettings);
    _loadAllData();
  }

  Future<void> _resetApp() async {
    await _firebaseService.clearAllProducts();
    await _storageService.clearSharedPrefs();
    _loadAllData();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardScreen(
        categories: _categories,
        settings: _settings,
        onNavigateToCategory: _navigateToProductList,
      ),
      AnalyticsScreen(categories: _categories),
      ShoppingListScreen(storageService: _storageService),
      SettingsScreen(
        settings: _settings,
        onSettingsChanged: _saveSettings,
        onResetApp: _resetApp,
        themeNotifier: widget.themeNotifier,
        storageService: _storageService,
      ),
    ];

    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_rounded),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_rounded),
            label: 'Shopping',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _navigateToProductList(Category category) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder:
                (context) => ProductListScreen(
                  category: category,
                  firebaseService: _firebaseService,
                ),
          ),
        )
        .then((_) => _loadAllData());
  }
}
