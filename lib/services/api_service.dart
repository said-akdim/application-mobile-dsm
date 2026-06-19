import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/models.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  String? _sessionId;
  String? _userName;
  bool get isLoggedIn => _sessionId != null;
  String get userName => _userName ?? '';

  Map<String, String> get _headers {
    final h = {'Content-Type': 'application/json'};
    if (_sessionId != null) h['Cookie'] = 'session_id=$_sessionId';
    return h;
  }

  /// Odoo attend une enveloppe JSON-RPC ; le résultat utile est dans `result`.
  Future<dynamic> _call(String path, Map<String, dynamic> params) async {
    final uri = Uri.parse('${AppConfig.baseUrl}$path');
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'method': 'call',
      'params': params,
    });

    final http.Response res;
    try {
      res = await http.post(uri, headers: _headers, body: body);
    } catch (_) {
      throw ApiException('Impossible de joindre le serveur.');
    }

    if (res.statusCode != 200) {
      throw ApiException('Erreur réseau (${res.statusCode}).');
    }

    // Récupère le cookie de session (présent surtout au login).
    final setCookie = res.headers['set-cookie'];
    if (setCookie != null) {
      final m = RegExp(r'session_id=([^;]+)').firstMatch(setCookie);
      if (m != null) _sessionId = m.group(1);
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    if (decoded['error'] != null) {
      final err = decoded['error'];
      final msg = err is Map
          ? (err['data']?['message'] ?? err['message'] ?? 'Erreur Odoo')
          : 'Erreur Odoo';
      throw ApiException(msg.toString());
    }
    return decoded['result'];
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

  void logout() => _sessionId = null;

  /// En-têtes pour charger les images protégées d'Odoo (cookie de session).
  Map<String, String> get imageHeaders =>
      _sessionId != null ? {'Cookie': 'session_id=$_sessionId'} : {};

  // --- Parcours scolaire ---

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

  // --- Catalogue (commande classique) ---

  Future<List<Product>> getProducts({String? search, int limit = 50}) async {
    final data = await _call('/api/products', {
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return (data as List).map((e) => Product.fromJson(e)).toList();
  }

  // --- Commandes ---

  Future<OrderSummary> createOrder(
      List<Map<String, dynamic>> lines,
      {String paymentMethod = 'cod', String? note}) async {
    final data = await _call('/api/order/create', {
      'lines': lines,
      'payment_method': paymentMethod,
      if (note != null) 'note': note,
    });
    if (data is Map && data['error'] != null) {
      throw ApiException(data['error'].toString());
    }
    return OrderSummary.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// URL du portail Odoo pour payer la commande en ligne.
  Future<String> getPaymentLink(int orderId) async {
    final data = await _call('/api/order/payment_link', {'order_id': orderId});
    if (data is Map && data['error'] != null) {
      throw ApiException(data['error'].toString());
    }
    return (data as Map)['url'] as String;
  }

  Future<List<OrderSummary>> getOrders() async {
    final data = await _call('/api/order/list', {});
    return (data as List).map((e) => OrderSummary.fromJson(e)).toList();
  }
}
