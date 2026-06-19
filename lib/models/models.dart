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

/// Un produit/livre, avec toutes ses métadonnées.
class Product {
  final int productId;
  final String name;
  final double price;
  final double qtyAvailable;
  final double quantity;
  final bool mandatory;
  // Métadonnées livre
  final String? authors;
  final String? editor;
  final String? editionYear;
  final String? isbn;
  final String? ean13;
  final String? summary;
  final String? category;
  final String? language;
  final String? collection;
  final int? pageCount;
  final double? weight;
  final double? length;
  final double? width;
  final double? thickness;
  final bool isNew;

  Product({
    required this.productId,
    required this.name,
    required this.price,
    required this.qtyAvailable,
    this.quantity = 1,
    this.mandatory = false,
    this.authors,
    this.editor,
    this.editionYear,
    this.isbn,
    this.ean13,
    this.summary,
    this.category,
    this.language,
    this.collection,
    this.pageCount,
    this.weight,
    this.length,
    this.width,
    this.thickness,
    this.isNew = false,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        productId: j['product_id'] as int,
        name: j['name'] as String,
        price: (j['price'] as num).toDouble(),
        qtyAvailable: (j['qty_available'] as num?)?.toDouble() ?? 0,
        quantity: (j['quantity'] as num?)?.toDouble() ?? 1,
        mandatory: j['mandatory'] as bool? ?? false,
        authors: j['authors'] as String?,
        editor: j['editor'] as String?,
        editionYear: j['edition_year'] as String?,
        isbn: j['isbn'] as String?,
        ean13: j['ean13'] as String?,
        summary: j['summary'] as String?,
        category: j['category'] as String?,
        language: j['language'] as String?,
        collection: j['collection'] as String?,
        pageCount: j['page_count'] as int?,
        weight: (j['weight'] as num?)?.toDouble(),
        length: (j['length'] as num?)?.toDouble(),
        width: (j['width'] as num?)?.toDouble(),
        thickness: (j['thickness'] as num?)?.toDouble(),
        isNew: j['is_new'] as bool? ?? false,
      );

  String? get dimensions {
    if (length != null && width != null && thickness != null) {
      return '${length!.toStringAsFixed(1)} × ${width!.toStringAsFixed(1)} × ${thickness!.toStringAsFixed(1)} cm';
    }
    return null;
  }
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
