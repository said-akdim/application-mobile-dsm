import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class CmiPaymentScreen extends StatefulWidget {
  final int orderId;      // ID de la commande Odoo (ex: 452)
  final int providerId;  // ID de la configuration CMI dans Odoo (ex: 3)
  final String odooUrl;   // URL de votre site Odoo (ex: https://votre-site.com)
  final String sessionId; // Le session_id récupéré lors de la connexion du client

  const CmiPaymentScreen({
    Key? key,
    required this.orderId,
    required this.providerId,
    required this.odooUrl,
    required this.sessionId,
  }) : super(key: key);

  @override
  State<CmiPaymentScreen> createState() => _CmiPaymentScreenState();
}

class _CmiPaymentScreenState extends State<CmiPaymentScreen> {
  late final WebViewController _webViewController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCmiPaymentData();
  }

  // 1. Appel de l'API Odoo pour récupérer les paramètres CMI
  Future<void> _fetchCmiPaymentData() async {
    final apiUrl = Uri.parse('${widget.odooUrl}/api/payment/cmi/get_form_values');
    
    try {
      final response = await http.post(
        apiUrl,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'session_id=${widget.sessionId}', // Authentification Odoo
        },
        body: jsonEncode({
          'params': {
            'order_id': widget.orderId,
            'provider_id': widget.providerId,
          }
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse['result'] != null && jsonResponse['result']['status'] == 'success') {
          final result = jsonResponse['result'];
          final String cmiUrl = result['cmi_url'];
          final Map<String, dynamic> formData = Map<String, dynamic>.from(result['form_data']);

          // Charger la WebView avec les données reçues
          _initWebView(cmiUrl, formData);
        } else {
          setState(() {
            _errorMessage = jsonResponse['result']?['message'] ?? "Erreur lors de la génération du paiement.";
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = "Erreur serveur Odoo (Status: ${response.statusCode})";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Impossible de se connecter à Odoo: $e";
        _isLoading = false;
      });
    }
  }

  // 2. Initialisation et configuration de la WebView en méthode POST
  void _initWebView(String cmiUrl, Map<String, dynamic> formData) {
    // Convertir le dictionnaire de données en format d'URL (x-www-form-urlencoded)
    final String postDataString = formData.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
    
    final Uint8List postDataBytes = Uint8List.fromList(utf8.encode(postDataString));

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            // 3. Écouter le changement d'URL pour détecter la fin du paiement
            // Si l'URL redirige vers Odoo, c'est que le traitement CMI est terminé
            if (url.contains('/payment/cmi/return') || url.contains('/shop/confirmation')) {
              // Fermer cet écran et retourner 'true' pour indiquer un succès
              Navigator.pop(context, true); 
            } else if (url.contains('/payment/cmi/error')) {
              // Fermer cet écran et retourner 'false' en cas d'échec
              Navigator.pop(context, false);
            }
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      // Exécuter la requête POST vers le serveur du CMI
      ..loadRequest(
        Uri.parse(cmiUrl),
        method: LoadRequestMethod.post,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: postDataBytes,
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Paiement Sécurisé CMI"),
        backgroundColor: Colors.blue[800], // Couleur aux choix
      ),
      body: Stack(
        children: [
          // Si l'erreur survient
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16)),
              ),
            ),

          // Affichage de la WebView une fois les données chargées
          if (_errorMessage == null && !_isLoading)
            WebViewWidget(controller: _webViewController),

          // Indicateur de chargement
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}