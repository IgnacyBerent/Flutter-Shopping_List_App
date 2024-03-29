import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list_app/models/grocery_item.dart';
import 'package:shopping_list_app/screens/new_item.dart';
import 'package:shopping_list_app/widgets/grocery_list_item.dart';
import 'package:shopping_list_app/data/categories.dart';
import 'package:http/http.dart' as http;

class GroceriesScreen extends StatefulWidget {
  const GroceriesScreen({super.key});

  @override
  State<GroceriesScreen> createState() => _GroceriesScreenState();
}

class _GroceriesScreenState extends State<GroceriesScreen> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
        'flutter-shoppingapp-31246-default-rtdb.europe-west1.firebasedatabase.app',
        'shopping-list.json');

    try {
      final response = await http.get(url);

      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed to fetch data. Please try again later';
        });
      }

      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadedItems = [];
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
              (element) => element.value.title == item.value['category'],
            )
            .value;
        loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        );
      }
      setState(() {
        _groceryItems = loadedItems;
      });
    } catch (error) {
      setState(() {
        _error = 'Something went wrong!. Please try again later';
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItemScreen(),
      ),
    );

    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
      _isLoading = false;
    });
  }

  void _removeItem(GroceryItem item) async {
    final itemIndex = _groceryItems.indexOf(item);

    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https(
        'flutter-shoppingapp-31246-default-rtdb.europe-west1.firebasedatabase.app',
        'shopping-list/${item.id}.json');

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        // Optional: show error message
        _groceryItems.insert(itemIndex, item);
      });
    }
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} removed.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _groceryItems.insert(itemIndex, item);
            });
            http.post(
              url,
              headers: {
                'Content-Type': 'application/json',
              },
              body: json.encode(
                {
                  'id': item.id,
                  'name': item.name,
                  'quantity': item.quantity,
                  'category': item.category.title,
                },
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Text('No items added yet!');

    if (_isLoading) {
      content = const CircularProgressIndicator();
    }

    if (_groceryItems.isNotEmpty) {
      setState(() {
        content = ListView.builder(
          itemCount: _groceryItems.length,
          itemBuilder: (ctx, index) => Dismissible(
            key: ValueKey(_groceryItems[index].id),
            background: Container(
              color: Theme.of(context).colorScheme.error,
            ),
            onDismissed: (direction) {
              _removeItem(_groceryItems[index]);
            },
            child: GroceryListItem(
              groceryItem: _groceryItems[index],
            ),
          ),
        );
      });
    }

    if (_error != null) {
      content = Text(_error!);
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          )
        ],
        title: const Text('Your Groceries'),
      ),
      body: Center(
        child: content,
      ),
    );
  }
}
