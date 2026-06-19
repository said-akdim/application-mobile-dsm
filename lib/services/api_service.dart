import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/models.dart';

class ApiException implements Exception {
  final String message;
  final bool isAuthError;
  ApiException(this.message, {this.isAuthError = false});
  @override
  String toString() => message;
}

class ApiService {
  String? _sessionId;
  String? _userName;
  bool get isLoggedIn => _sessionId != null;
  String get userName => _userName ?? '';
  String get sessionId => _sessionId ?? '';

  Map<String, String> get _headers {
    final h = {'Content-Type': 'application/json'};
    if (_sessionId != null) h['Cookie'] = 'session_id=$_sessionId';
    return h;
  }

  Future<dynamic> _call(String path, Map<String, dynamic> params) async {
    final uri = Uri.parse('${AppConfig.baseUrl}$path');
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'method': 'call',
      'params': params,
    });

    final http.Response res;
    try {
      res = await http
          .post(uri, headers: _headers, body: body)
          .timeout(const Duration(seconds: AppConfig.networkTimeout));
    } on Exception {
      throw ApiException('Impossible de joindre le serveur. Vérifiez votre connexion.');
    }

    if (res.statusCode == 401) {
      _sessionId = null;
      throw ApiException('Session expirée. Veuillez vous reconnecter.', isAuthError: true);
    }
    if (res.statusCode != 200) {
      throw ApiException('Erreur réseau. Veuillez réessayer.');
    }

    final setCookie = res.headers['set-cookie'];
    if (setCookie != null) {
      final m = RegExp(r'session_id=([^;]+)').firstMatch(setCookie);
      if (m != null) _sessionId = m.group(1);
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    if (decoded['error'] != null) {
      final err = decoded['error'];
      if (err is Map) {
        final code = err['code'];
        final data = err['data'];
        // Session invalide dans Odoo (code 100 ou type session_expired)
        if (code == 100 ||
            (data is Map && data['name']?.toString().contains('session') == true)) {
          _sessionId = null;
          throw ApiException('Session expirée. Veuillez vous reconnecter.', isAuthError: true);
        }
        // Message d'erreur filtré : ne pas exposer les détails internes Odoo
        final userMsg = _sanitizeError(data);
        throw ApiException(userMsg);
      }
      throw ApiException('Une erreur est survenue. Veuillez réessayer.');
    }
    return decoded['result'];
  }

  String _sanitizeError(dynamic data) {
    if (data is! Map) return 'Une erreur est survenue. Veuillez réessayer.';
    final msg = data['message']?.toString() ?? '';
    // Messages métier lisibles — on les transmet
    if (msg.contains('Stock') || msg.contains('stock') ||
        msg.contains('disponible') || msg.contains('introuvable') ||
        msg.contains('Identifiants')) {
      return msg;
    }
    // Tout le reste (erreurs techniques Odoo) → message générique
    return 'Une erreur est survenue. Veuillez réessayer.';
  }

  Future<void> login(String login, String password) async {
    final result = await _call('/web/session/authenticate', {
      'db': AppConfig.dbName,
      'login': login,
      'password': password,
    });
    if (result is! Map || result['uid'] == null) {
      throw ApiException('Identifiants invalides.');
    }
    _userName = (result['name'] ?? result['username'] ?? login).toString();
  }

  void logout() {
    _sessionId = null;
    _userName = null;
  }

  Map<String, String> get imageHeaders =>
      _sessionId != null ? {'Cookie': 'session_id=$_sessionId'} : {};

  Future<List<City>> getCities() async {
    final data = await _call('/api/cities', {});
    return (data as List).map((e) => City.fromJson(e)).toList();
  }

  Future<List<School>> getSchools(int cityId) async {
    final data = await _call('/api/schools', {'city_id': cityId});
    return (data as List).map((e) => School.fromJson(e)).toList();
  }

  Future<List<Level>> getLevels(int schoolId) async {
    final data = await _call('/api/levels', {'school_id': schoolId});
    return (data as List).map((e) => Level.fromJson(e)).toList();
  }

  Future<List<Product>> getBooklist(int schoolId, int levelId) async {
    final data = await _call('/api/booklist', {
      'school_id': schoolId,
      'level_id': levelId,
    });
    if (data is Map && data['error'] != null) {
      throw ApiException(data['error'].toString());
    }
    final lines = (data as Map)['lines'] as List;
    return lines.map((e) => Product.fromJson(e)).toList();
  }

  Future<List<Product>> getProducts({String? search, int limit = 50}) async {
    final data = await _call('/api/products', {
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return (data as List).map((e) => Product.fromJson(e)).toList();
  }

  Future<OrderSummary> createOrder(
      List<Map<String, dynamic>> lines,
      {String paymentMethod = 'cod', String? note}) async {
    if (lines.isEmpty) throw ApiException('Le panier est vide.');
    final data = await _call('/api/order/create', {
      'lines': lines,
      'payment_method': paymentMethod,
      if (note != null) 'note': note,
    });
    return OrderSummary.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<String> getPaymentLink(int orderId) async {
    final data = await _call('/api/order/payment_link', {'order_id': orderId});
    String url = (data as Map)['url'] as String;
    // Sur émulateur Android, localhost Odoo → 10.0.2.2
    url = url.replaceFirst('http://localhost:', 'http://${Uri.parse(AppConfig.baseUrl).host}:');
    return url;
  }

  Future<List<OrderSummary>> getOrders() async {
    final data = await _call('/api/order/list', {});
    return (data as List).map((e) => OrderSummary.fromJson(e)).toList();
  }
}
