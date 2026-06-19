import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../models/models.dart';

class ApiException implements Exception {
  final String message;
  final bool isAuthError;
  ApiException(this.message, {this.isAuthError = false});
  @override
  String toString() => message;
}

class ApiService extends ChangeNotifier {
  String? _sessionId;
  String? _userName;
  bool _isAuthenticated = false;

  bool get isLoggedIn => _isAuthenticated;
  String get userName => _userName ?? '';
  String get sessionId => _sessionId ?? '';

  static const _kSessionId = 'dsm_session_id';
  static const _kUserName = 'dsm_user_name';

  Map<String, String> get _headers {
    final h = {'Content-Type': 'application/json'};
    if (_sessionId != null) h['Cookie'] = 'session_id=$_sessionId';
    return h;
  }

  Map<String, String> get imageHeaders =>
      _sessionId != null ? {'Cookie': 'session_id=$_sessionId'} : {};

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
      throw ApiException(
          'Impossible de joindre le serveur. Vérifiez votre connexion.');
    }

    if (res.statusCode == 401) {
      _clearAuth();
      throw ApiException('Session expirée. Veuillez vous reconnecter.',
          isAuthError: true);
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
        if (code == 100 ||
            (data is Map &&
                data['name']?.toString().contains('session') == true)) {
          _clearAuth();
          throw ApiException('Session expirée. Veuillez vous reconnecter.',
              isAuthError: true);
        }
        final userMsg = _sanitizeError(data);
        throw ApiException(userMsg);
      }
      throw ApiException('Une erreur est survenue. Veuillez réessayer.');
    }
    return decoded['result'];
  }

  void _clearAuth() {
    _isAuthenticated = false;
    _sessionId = null;
    _userName = null;
    _deleteSavedSession();
    notifyListeners();
  }

  String _sanitizeError(dynamic data) {
    if (data is! Map) return 'Une erreur est survenue. Veuillez réessayer.';
    final msg = data['message']?.toString() ?? '';
    if (msg.contains('Stock') ||
        msg.contains('stock') ||
        msg.contains('disponible') ||
        msg.contains('introuvable') ||
        msg.contains('Identifiants')) {
      return msg;
    }
    return 'Une erreur est survenue. Veuillez réessayer.';
  }

  // ── Authentification ──────────────────────────────────────────────────────

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
    _isAuthenticated = true;
    await _saveSession();
    notifyListeners();
  }

  void logout() {
    _clearAuth();
  }

  // Tente de restaurer la session sauvegardée. Retourne true si réussi.
  Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sid = prefs.getString(_kSessionId);
    final name = prefs.getString(_kUserName);
    if (sid == null || sid.isEmpty) return false;
    _sessionId = sid;
    _userName = name;
    try {
      await _call('/api/order/list', {});
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (_) {
      _sessionId = null;
      _userName = null;
      await _deleteSavedSession();
      return false;
    }
  }

  Future<void> _saveSession() async {
    if (_sessionId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSessionId, _sessionId!);
    await prefs.setString(_kUserName, _userName ?? '');
  }

  Future<void> _deleteSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSessionId);
    await prefs.remove(_kUserName);
  }

  // ── Catalogue public (sans connexion) ────────────────────────────────────

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

  // ── Commandes (connexion requise) ─────────────────────────────────────────

  Future<OrderSummary> createOrder(List<Map<String, dynamic>> lines,
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
    url = url.replaceFirst('http://localhost:',
        'http://${Uri.parse(AppConfig.baseUrl).host}:');
    return url;
  }

  Future<List<OrderSummary>> getOrders() async {
    final data = await _call('/api/order/list', {});
    return (data as List).map((e) => OrderSummary.fromJson(e)).toList();
  }
}
