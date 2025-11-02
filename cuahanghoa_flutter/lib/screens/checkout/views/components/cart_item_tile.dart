import 'package:flutter/material.dart';
import 'package:cuahanghoa_flutter/models/cart_item.dart';

class CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  const CartItemTile({
    super.key,
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          color: Colors.grey.shade300,
          child: item.imageUrl.isNotEmpty
              ? Image.network(item.imageUrl, fit: BoxFit.cover)
              : const Icon(Icons.image_not_supported),
        ),
        title: Text(item.name),
        subtitle: Text('Giá: ${item.price.toStringAsFixed(0)} ₫'),
        trailing: SizedBox(
          width: 120,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: onDecrease,
              ),
              Text('${item.quantity}'),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: onIncrease,
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
