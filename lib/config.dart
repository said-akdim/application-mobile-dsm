class AppConfig {
  static const String baseUrl = 'http://10.0.2.2:8169';
  static const String dbName = 'agora';
}

class AppFormat {
  static const String currency = 'Dhs';
  static String money(num v) => '${v.toStringAsFixed(2)} $currency';

  static String productImage(int productId, {int size = 256}) =>
      '${AppConfig.baseUrl}/web/image/product.product/$productId/image_$size';
}