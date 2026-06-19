class AppConfig {
  // URL du serveur Odoo — en production remplacer par https://votre-domaine.ma
  static const String baseUrl =
      String.fromEnvironment('ODOO_URL', defaultValue: 'http://localhost:9069');

  // Nom de la base de données Odoo
  static const String dbName =
      String.fromEnvironment('ODOO_DB', defaultValue: 'agora-dev');

  // Timeout réseau (secondes)
  static const int networkTimeout = 15;
}

class AppFormat {
  static const String currency = 'Dhs';
  static String money(num v) => '${v.toStringAsFixed(2)} $currency';

  static String productImage(int productId, {int size = 256}) =>
      '${AppConfig.baseUrl}/web/image/product.product/$productId/image_$size';
}
