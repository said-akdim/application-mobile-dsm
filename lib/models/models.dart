class City {
  final int id;
  final String name;
  City({required this.id, required this.name});
  factory City.fromJson(Map<String, dynamic> j) =>
      City(id: j['id'] as int, name: j['name'] as String);
}

class School {
  final int id;
  final String name;
  School({required this.id, required this.name});
  factory School.fromJson(Map<String, dynamic> j) =>
      School(id: j['id'] as int, name: j['name'] as String);
}

class Level {
  final int id;
  final String name;
  Level({required this.id, required this.name});
  factory Level.fromJson(Map<String, dynamic> j) =>
      Level(id: j['id'] as int, name: j['name'] as String);
}

/// Un produit, qu'il vienne d'une liste scolaire ou du catalogue.
class Product {
  final int productId;
  final String name;
  final double price;
  final double qtyAvailable;
  final double quantity; // quantité conseillée (listes scolaires)
  final bool mandatory; // obligatoire (listes scolaires)

  Product({
    required this.productId,
    required this.name,
    required this.price,
    required this.qtyAvailable,
    this.quantity = 1,
    this.mandatory = false,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        productId: j['product_id'] as int,
        name: j['name'] as String,
        price: (j['price'] as num).toDouble(),
        qtyAvailable: (j['qty_available'] as num?)?.toDouble() ?? 0,
        quantity: (j['quantity'] as num?)?.toDouble() ?? 1,
        mandatory: j['mandatory'] as bool? ?? false,
      );
}

class OrderSummary {
  final int orderId;
  final String name;
  final double amountTotal;
  final String state;
  OrderSummary({
    required this.orderId,
    required this.name,
    required this.amountTotal,
    required this.state,
  });
  factory OrderSummary.fromJson(Map<String, dynamic> j) => OrderSummary(
        orderId: j['order_id'] as int,
        name: j['name'] as String,
        amountTotal: (j['amount_total'] as num).toDouble(),
        state: j['state'] as String,
      );
}
