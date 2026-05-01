import 'product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
}

class Order {
  final String id;
  final List<CartItem> items;
  final double totalAmount;
  final DateTime date;
  final String status;

  Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.date,
    this.status = 'Pending',
  });
}
