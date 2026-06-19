import 'package:flutter/foundation.dart';
import '../models/models.dart';

class CartLine {
  final int productId;
  final String name;
  final double price;
  double quantity;
  CartLine({
    required this.productId,
    required this.name,
    required this.price,
    this.quantity = 1,
  });
}

class Cart extends ChangeNotifier {
  final Map<int, CartLine> _lines = {};

  List<CartLine> get lines => _lines.values.toList();
  int get count => _lines.length;
  bool get isEmpty => _lines.isEmpty;
  double get total =>
      _lines.values.fold(0.0, (s, l) => s + l.price * l.quantity);

  bool contains(int productId) => _lines.containsKey(productId);

  void add(Product p, {double quantity = 1}) {
    final existing = _lines[p.productId];
    if (existing != null) {
      existing.quantity += quantity;
    } else {
      _lines[p.productId] = CartLine(
        productId: p.productId,
        name: p.name,
        price: p.price,
        quantity: quantity,
      );
    }
    notifyListeners();
  }

  void setQuantity(int productId, double quantity) {
    final l = _lines[productId];
    if (l == null) return;
    if (quantity <= 0) {
      _lines.remove(productId);
    } else {
      l.quantity = quantity;
    }
    notifyListeners();
  }

  void remove(int productId) {
    _lines.remove(productId);
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    notifyListeners();
  }

  List<Map<String, dynamic>> toOrderLines() => _lines.values
      .map((l) => {'product_id': l.productId, 'quantity': l.quantity})
      .toList();
}
