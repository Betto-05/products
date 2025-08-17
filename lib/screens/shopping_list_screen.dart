// lib/screens/shopping_list_screen.dart
import 'package:flutter/material.dart';
import 'package:products/models/models.dart';
import 'package:products/services/storage_services.dart';

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
