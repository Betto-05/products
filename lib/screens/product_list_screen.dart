// lib/screens/product_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:products/models/models.dart';
import 'package:products/services/firebase_services.dart';

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
