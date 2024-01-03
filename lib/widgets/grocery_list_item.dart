import 'package:flutter/material.dart';
import 'package:shopping_list_app/models/grocery_item.dart';

class GroceryListItem extends StatelessWidget {
  const GroceryListItem({
    super.key,
    required this.groceryItem,
  });

  final GroceryItem groceryItem;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            color: groceryItem.category.color,
          ),
          const SizedBox(width: 16),
          Text(groceryItem.name),
          const Spacer(),
          Text(groceryItem.quantity.toString()),
        ],
      ),
    );
  }
}
