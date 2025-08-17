// --- PRODUCT LIST SCREEN ---
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:products/models/category.dart';
import 'package:products/models/product.dart';

class ProductListScreen extends StatefulWidget {
  final Category category;
  final Future<void> Function() onDataChanged;

  const ProductListScreen({
    super.key,
    required this.category,
    required this.onDataChanged,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<Product> _products;

  @override
  void initState() {
    super.initState();
    _products = widget.category.products;
  }

  Future<void> _addProduct(Product product) async {
    setState(() => _products.insert(0, product));
    _listKey.currentState?.insertItem(
      0,
      duration: const Duration(milliseconds: 500),
    );
    await widget.onDataChanged();
  }

  Future<void> _removeProduct(int index) async {
    final removedProduct = _products.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) =>
          _buildProductItem(context, removedProduct, animation, index),
      duration: const Duration(milliseconds: 500),
    );
    setState(() {});
    await widget.onDataChanged();
  }

  void _showAddProductSheet() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    DateTime? selectedDate = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
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
                          'Add New Product',
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Exp: ${DateFormat.yMMMd().format(selectedDate!)}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.calendar_today,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                                onPressed: () async {
                                  final pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate!,
                                    firstDate: DateTime.now().subtract(
                                      const Duration(days: 365),
                                    ),
                                    lastDate: DateTime(2101),
                                  );
                                  if (pickedDate != null) {
                                    setModalState(
                                      () => selectedDate = pickedDate,
                                    );
                                  }
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
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                _addProduct(
                                  Product(
                                    id: DateTime.now().toIso8601String(),
                                    name: nameController.text,
                                    quantity: int.parse(
                                      quantityController.text,
                                    ),
                                    expiryDate: selectedDate!,
                                  ),
                                );
                                Navigator.pop(context);
                              }
                            },
                            child: const Text(
                              'Add Product',
                              style: TextStyle(
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.category.icon, color: widget.category.color),
            const SizedBox(width: 8),
            Text(widget.category.name),
          ],
        ),
      ),
      body:
          _products.isEmpty
              ? _buildEmptyState()
              : AnimatedList(
                key: _listKey,
                initialItemCount: _products.length,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemBuilder:
                    (context, index, animation) => _buildProductItem(
                      context,
                      _products[index],
                      animation,
                      index,
                    ),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProductSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No Products Yet',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first product.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(
    BuildContext context,
    Product product,
    Animation<double> animation,
    int index,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDay = DateTime(
      product.expiryDate.year,
      product.expiryDate.month,
      product.expiryDate.day,
    );
    final difference = expiryDay.difference(today).inDays;

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

    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
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
              onPressed: () => _removeProduct(index),
            ),
          ),
        ),
      ),
    );
  }
}
