import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
// NEW: Import Firebase Authentication
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- MODELS with JSON Serialization ---
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

// NEW: Theme Notifier to manage app theme state
class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode;
  ThemeNotifier(this._themeMode);
  ThemeMode get themeMode => _themeMode;
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}

// --- NEW: AUTHENTICATION SERVICE ---
class AuthService {
  final _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() {
    return _auth.signOut();
  }
}

// --- MODIFIED: FIREBASE SERVICE for product data (now user-specific) ---
class FirebaseService {
  final _firestore = FirebaseFirestore.instance;

  // Helper to get the current user's ID
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
    if (userId == null)
      return getInitialCategories(); // Return empty if no user

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

// --- STORAGE SERVICE (for SharedPreferences data) ---
class StorageService {
  static const _shoppingListKey = 'shopping_list';
  static const _settingsKey = 'app_settings';
  static const _themeKey = 'app_theme';

  Future<void> saveShoppingList(List<ShoppingListItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _shoppingListKey,
      jsonEncode(items.map((i) => i.toJson()).toList()),
    );
  }

  Future<List<ShoppingListItem>> loadShoppingList() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_shoppingListKey);
    if (data == null) return [];
    return (jsonDecode(data) as List)
        .map((i) => ShoppingListItem.fromJson(i))
        .toList();
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings));
  }

  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_settingsKey);
    if (data == null) return {'expiringSoonDays': 7}; // Default value
    return jsonDecode(data);
  }

  Future<void> saveTheme(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeMode.name);
  }

  Future<ThemeMode> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themeKey) ?? ThemeMode.system.name;
    return ThemeMode.values.firstWhere((e) => e.name == themeName);
  }

  Future<void> clearSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_shoppingListKey);
    await prefs.remove(_settingsKey);
    // Note: We don't remove the theme key, as it's a persistent user preference.
  }
}

// --- MAIN APP ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final storageService = StorageService();
  final themeMode = await storageService.loadTheme();

  runApp(ProductManagementApp(initialThemeMode: themeMode));
}

class ProductManagementApp extends StatefulWidget {
  final ThemeMode initialThemeMode;
  const ProductManagementApp({super.key, required this.initialThemeMode});

  @override
  State<ProductManagementApp> createState() => _ProductManagementAppState();
}

class _ProductManagementAppState extends State<ProductManagementApp> {
  late ThemeNotifier _themeNotifier;

  @override
  void initState() {
    super.initState();
    _themeNotifier = ThemeNotifier(widget.initialThemeMode);
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF276749);
    const Color secondaryColor = Color(0xFF38A169);

    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFFF7FAFC),
      fontFamily: 'Gilroy',
      cardColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF2D3748),
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      textTheme: Theme.of(context).textTheme.apply(
        fontFamily: 'Gilroy',
        bodyColor: const Color(0xFF2D3748),
        displayColor: const Color(0xFF2D3748),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF2D3748)),
        titleTextStyle: TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF2D3748),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        showUnselectedLabels: false,
      ),
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFF1A202C),
      fontFamily: 'Gilroy',
      cardColor: const Color(0xFF2D3748),
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Color(0xFF2D3748),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFFEDF2F7),
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      textTheme: Theme.of(context).textTheme.apply(
        fontFamily: 'Gilroy',
        bodyColor: const Color(0xFFEDF2F7),
        displayColor: const Color(0xFFEDF2F7),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFFEDF2F7)),
        titleTextStyle: TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFFEDF2F7),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF2D3748),
        selectedItemColor: secondaryColor,
        unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        showUnselectedLabels: false,
      ),
      inputDecorationTheme: const InputDecorationTheme(filled: true),
    );

    return AnimatedBuilder(
      animation: _themeNotifier,
      builder: (context, _) {
        return MaterialApp(
          title: 'Stock Up',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: _themeNotifier.themeMode,
          home: SplashScreen(themeNotifier: _themeNotifier),
        );
      },
    );
  }
}

// --- SPLASH SCREEN with Animation ---
class SplashScreen extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const SplashScreen({super.key, required this.themeNotifier});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoFadeAnimation;
  late Animation<Offset> _logoSlideAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            // MODIFIED: Navigate to AuthGate instead of HomePage
            pageBuilder:
                (_, __, ___) => AuthGate(themeNotifier: widget.themeNotifier),
            transitionsBuilder:
                (_, a, __, c) => FadeTransition(opacity: a, child: c),
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SlideTransition(
              position: _logoSlideAnimation,
              child: FadeTransition(
                opacity: _logoFadeAnimation,
                child: SizedBox(
                  height: 200,
                  child: Image.asset('assets/logo.png'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SlideTransition(
              position: _textSlideAnimation,
              child: FadeTransition(
                opacity: _textFadeAnimation,
                child: Text(
                  'Stock Up',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            SlideTransition(
              position: _textSlideAnimation,
              child: FadeTransition(
                opacity: _textFadeAnimation,
                child: Text(
                  'Stay fresh. Stay stocked',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- NEW: AUTH GATE (Checks login state) ---
class AuthGate extends StatelessWidget {
  final ThemeNotifier themeNotifier;
  const AuthGate({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        // Show a loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // User is logged in, go to the main app
        if (snapshot.hasData) {
          return HomePage(themeNotifier: themeNotifier);
        }
        // User is not logged in, show the login screen
        return LoginScreen(themeNotifier: themeNotifier);
      },
    );
  }
}

// --- NEW: LOGIN SCREEN ---
class LoginScreen extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const LoginScreen({super.key, required this.themeNotifier});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      // AuthGate will handle navigation
    } on FirebaseAuthException catch (e) {
      final snackBar = SnackBar(
        content: Text(e.message ?? "An error occurred."),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset('assets/logo.png', height: 150),
                const SizedBox(height: 16),
                Text(
                  "Welcome Back!",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Sign in to continue",
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator:
                      (v) =>
                          v!.isEmpty || !v.contains('@')
                              ? 'Enter a valid email'
                              : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed:
                          () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible,
                          ),
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? 'Password is required' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                          : const Text('Login', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (context) => RegisterScreen(
                              themeNotifier: widget.themeNotifier,
                            ),
                      ),
                    );
                  },
                  child: const Text("Don't have an account? Register"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- NEW: REGISTER SCREEN ---
class RegisterScreen extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const RegisterScreen({super.key, required this.themeNotifier});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _authService.createUserWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      // AuthGate will handle navigation
    } on FirebaseAuthException catch (e) {
      final snackBar = SnackBar(
        content: Text(e.message ?? "An error occurred."),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Create Account",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Start managing your pantry today!",
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator:
                      (v) =>
                          v!.isEmpty || !v.contains('@')
                              ? 'Enter a valid email'
                              : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed:
                          () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible,
                          ),
                    ),
                  ),
                  validator:
                      (v) =>
                          v!.length < 6
                              ? 'Password must be at least 6 characters'
                              : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                          : const Text(
                            'Register',
                            style: TextStyle(fontSize: 16),
                          ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Already have an account? Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- HOME PAGE (Manages Bottom Navigation) ---
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
    // MODIFIED: No longer resets theme, as it's a persistent preference
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

// --- DASHBOARD SCREEN ---
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

// --- ANALYTICS SCREEN ---
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

// --- SHOPPING LIST SCREEN ---
class ShoppingListScreen extends StatefulWidget {
  final StorageService storageService;
  const ShoppingListScreen({super.key, required this.storageService});
  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  List<ShoppingListItem> _items = [];
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    _items = await widget.storageService.loadShoppingList();
    setState(() {});
  }

  Future<void> _saveItems() => widget.storageService.saveShoppingList(_items);

  void _addItem() {
    if (_textController.text.isNotEmpty) {
      setState(
        () => _items.insert(
          0,
          ShoppingListItem(
            id: DateTime.now().toIso8601String(),
            name: _textController.text,
          ),
        ),
      );
      _textController.clear();
      _saveItems();
    }
  }

  void _toggleItem(int index) {
    setState(() => _items[index].isChecked = !_items[index].isChecked);
    _saveItems();
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
    _saveItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shopping List')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Add an item...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: _addItem,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _items.isEmpty
                    ? const Center(child: Text("Your shopping list is empty."))
                    : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Dismissible(
                          key: Key(item.id),
                          onDismissed: (_) => _removeItem(index),
                          background: Container(
                            color: Colors.red.shade300,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          child: CheckboxListTile(
                            title: Text(
                              item.name,
                              style: TextStyle(
                                decoration:
                                    item.isChecked
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                              ),
                            ),
                            value: item.isChecked,
                            onChanged: (_) => _toggleItem(index),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

// --- SETTINGS SCREEN ---
class SettingsScreen extends StatefulWidget {
  final Map<String, dynamic> settings;
  final Function(Map<String, dynamic>) onSettingsChanged;
  final Future<void> Function() onResetApp;
  final ThemeNotifier themeNotifier;
  final StorageService storageService;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    required this.onResetApp,
    required this.themeNotifier,
    required this.storageService,
  });
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _expiringDays;
  @override
  void initState() {
    super.initState();
    _expiringDays = (widget.settings['expiringSoonDays'] ?? 7).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? "No user";
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text("Logged in as"),
                subtitle: Text(
                  userEmail,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: SwitchListTile(
              title: const Text("Dark Mode"),
              secondary: const Icon(Icons.dark_mode_outlined),
              value: widget.themeNotifier.themeMode == ThemeMode.dark,
              onChanged: (value) {
                final newMode = value ? ThemeMode.dark : ThemeMode.light;
                widget.themeNotifier.setThemeMode(newMode);
                widget.storageService.saveTheme(newMode);
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Expiring Soon Threshold",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Notify about items expiring in the next ${_expiringDays.toInt()} days.",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Slider(
                    value: _expiringDays,
                    min: 1,
                    max: 14,
                    divisions: 13,
                    label: _expiringDays.round().toString(),
                    onChanged: (value) => setState(() => _expiringDays = value),
                    onChangeEnd:
                        (value) => widget.onSettingsChanged({
                          'expiringSoonDays': value.toInt(),
                        }),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color:
                Theme.of(context).brightness == Brightness.light
                    ? Colors.red.shade50
                    : Colors.red.shade900.withOpacity(0.4),
            child: ListTile(
              leading: Icon(
                Icons.warning_amber_rounded,
                color: Colors.red.shade700,
              ),
              title: Text(
                "Clear All Data",
                style: TextStyle(
                  color:
                      Theme.of(context).brightness == Brightness.light
                          ? Colors.red.shade900
                          : Colors.red.shade200,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                "This will delete all your products.",
                style: TextStyle(
                  color:
                      Theme.of(context).brightness == Brightness.light
                          ? Colors.red.shade800
                          : Colors.red.shade300,
                ),
              ),
              onTap:
                  () => showDialog(
                    context: context,
                    builder:
                        (ctx) => AlertDialog(
                          title: const Text("Are you sure?"),
                          content: const Text(
                            "This action cannot be undone. All your products and categories will be permanently deleted for this account.",
                          ),
                          actions: [
                            TextButton(
                              child: const Text("Cancel"),
                              onPressed: () => Navigator.of(ctx).pop(),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text("Delete Everything"),
                              onPressed: () {
                                widget.onResetApp();
                                Navigator.of(ctx).pop();
                              },
                            ),
                          ],
                        ),
                  ),
            ),
          ),
          const SizedBox(height: 16),
          // NEW: Sign Out Button
          Card(
            child: ListTile(
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text("Sign Out"),
              onTap: () async {
                await AuthService().signOut();
                // AuthGate will handle navigation
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- PRODUCT LIST SCREEN ---
enum ProductSortType { byName, byQuantity, byExpiry }

class ProductListScreen extends StatefulWidget {
  final Category category;
  final FirebaseService firebaseService;

  const ProductListScreen({
    super.key,
    required this.category,
    required this.firebaseService,
  });
  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  late List<Product> _allProducts;
  List<Product> _displayedProducts = [];
  String _searchQuery = '';
  ProductSortType _currentSort = ProductSortType.byExpiry;

  @override
  void initState() {
    super.initState();
    _allProducts = List.from(widget.category.products);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
      _filterAndSortProducts();
    });
    _filterAndSortProducts();
  }

  void _filterAndSortProducts() {
    List<Product> filtered =
        _allProducts
            .where(
              (p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();
    switch (_currentSort) {
      case ProductSortType.byName:
        filtered.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case ProductSortType.byQuantity:
        filtered.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
      case ProductSortType.byExpiry:
        filtered.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
        break;
    }
    setState(() => _displayedProducts = filtered);
  }

  void _changeSortType(ProductSortType newSortType) {
    setState(() => _currentSort = newSortType);
    _filterAndSortProducts();
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 24),
              Text(message),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleProductChange({required Product product}) async {
    await widget.firebaseService.saveProduct(widget.category.name, product);
    int index = _allProducts.indexWhere((p) => p.id == product.id);
    if (mounted) {
      setState(() {
        if (index != -1) {
          _allProducts[index] = product;
        } else {
          _allProducts.insert(0, product);
        }
        _filterAndSortProducts();
      });
    }
  }

  Future<void> _removeProduct(Product productToRemove) async {
    final originalIndex = _allProducts.indexWhere(
      (p) => p.id == productToRemove.id,
    );
    if (originalIndex == -1) return;
    final product = _allProducts[originalIndex];
    setState(() => _allProducts.removeAt(originalIndex));
    _filterAndSortProducts();
    await widget.firebaseService.deleteProduct(
      widget.category.name,
      productToRemove.id,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("'${product.name}' deleted"),
        action: SnackBarAction(
          label: "UNDO",
          onPressed: () async {
            setState(() => _allProducts.insert(originalIndex, product));
            _filterAndSortProducts();
            await widget.firebaseService.saveProduct(
              widget.category.name,
              product,
            );
          },
        ),
      ),
    );
  }

  void _showProductSheet({Product? productToEdit}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: productToEdit?.name);
    final quantityController = TextEditingController(
      text: productToEdit?.quantity.toString(),
    );
    DateTime selectedDate =
        productToEdit?.expiryDate ??
        DateTime.now().add(const Duration(days: 7));
    bool isEditing = productToEdit != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder:
                (ctx, setModalState) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? 'Edit Product' : 'Add New Product',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: 'Product Name',
                                border: OutlineInputBorder(),
                              ),
                              validator:
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? 'Please enter a name'
                                          : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: quantityController,
                              decoration: const InputDecoration(
                                labelText: 'Quantity',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator:
                                  (v) =>
                                      (v == null ||
                                              v.isEmpty ||
                                              int.tryParse(v) == null)
                                          ? 'Enter a valid number'
                                          : null,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Exp: ${DateFormat.yMMMd().format(selectedDate)}',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.calendar_today,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                    ),
                                    onPressed: () async {
                                      final pickedDate = await showDatePicker(
                                        context: context,
                                        initialDate: selectedDate,
                                        firstDate: DateTime.now().subtract(
                                          const Duration(days: 365),
                                        ),
                                        lastDate: DateTime(2101),
                                      );
                                      if (pickedDate != null)
                                        setModalState(
                                          () => selectedDate = pickedDate,
                                        );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.secondary,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onSecondary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () async {
                                  if (formKey.currentState!.validate()) {
                                    final newOrEditedProduct = Product(
                                      id:
                                          productToEdit?.id ??
                                          DateTime.now().toIso8601String(),
                                      name: nameController.text,
                                      quantity: int.parse(
                                        quantityController.text,
                                      ),
                                      expiryDate: selectedDate,
                                    );
                                    _showLoadingDialog(context, 'Saving...');
                                    try {
                                      await _handleProductChange(
                                        product: newOrEditedProduct,
                                      );
                                      if (!mounted) return;
                                      Navigator.of(
                                        context,
                                        rootNavigator: true,
                                      ).pop();
                                      Navigator.pop(context);
                                    } catch (e) {
                                      if (!mounted) return;
                                      Navigator.of(
                                        context,
                                        rootNavigator: true,
                                      ).pop();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Failed to save product. Please try again.',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Text(
                                  isEditing ? 'Save Changes' : 'Add Product',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 3.0,
                  children: [
                    ChoiceChip(
                      label: const Text('By Expiry'),
                      selected: _currentSort == ProductSortType.byExpiry,
                      onSelected:
                          (_) => _changeSortType(ProductSortType.byExpiry),
                      selectedColor: Theme.of(context).colorScheme.primary,
                      labelStyle: TextStyle(
                        color:
                            _currentSort == ProductSortType.byExpiry
                                ? Colors.white
                                : null,
                      ),
                    ),
                    ChoiceChip(
                      label: const Text('By Name'),
                      selected: _currentSort == ProductSortType.byName,
                      onSelected:
                          (_) => _changeSortType(ProductSortType.byName),
                      selectedColor: Theme.of(context).colorScheme.primary,
                      labelStyle: TextStyle(
                        color:
                            _currentSort == ProductSortType.byName
                                ? Colors.white
                                : null,
                      ),
                    ),
                    ChoiceChip(
                      label: const Text('By Quantity'),
                      selected: _currentSort == ProductSortType.byQuantity,
                      onSelected:
                          (_) => _changeSortType(ProductSortType.byQuantity),
                      selectedColor: Theme.of(context).colorScheme.primary,
                      labelStyle: TextStyle(
                        color:
                            _currentSort == ProductSortType.byQuantity
                                ? Colors.white
                                : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _displayedProducts.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: _displayedProducts.length,
                      itemBuilder:
                          (context, index) => _buildProductItem(
                            context,
                            _displayedProducts[index],
                          ),
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductSheet(),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(
          _searchQuery.isEmpty ? 'No Products Yet' : 'No Results Found',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        Text(
          _searchQuery.isEmpty
              ? 'Tap the + button to add one.'
              : "Try a different search term.",
          style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _buildProductItem(BuildContext context, Product product) {
    final difference =
        product.expiryDate
            .difference(
              DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
              ),
            )
            .inDays;
    Color expiryColor;
    String expiryText;
    if (difference < 0) {
      expiryColor = Colors.red.shade400;
      expiryText = 'Expired ${-difference}d ago';
    } else if (difference < 3) {
      expiryColor = Colors.amber.shade600;
      expiryText = 'Expires in ${difference + 1}d';
    } else {
      expiryColor = Colors.green.shade400;
      expiryText =
          'Expires on ${DateFormat.yMMMd().format(product.expiryDate)}';
    }
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: () => _showProductSheet(productToEdit: product),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        subtitle: Text(
          'Quantity: ${product.quantity}\n$expiryText',
          style: TextStyle(
            color: Theme.of(
              context,
            ).textTheme.bodySmall?.color?.withOpacity(0.8),
            height: 1.5,
          ),
        ),
        trailing: CircleAvatar(backgroundColor: expiryColor, radius: 8),
        isThreeLine: true,
        leading: IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => _removeProduct(product),
        ),
      ),
    );
  }
}
