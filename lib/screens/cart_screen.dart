import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../config.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../state/cart.dart';
import '../widgets/product_cover.dart';
import '../state/tab_notifier.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _sending = false;
  String _method = 'cod';

  Future<void> _validate() async {
    final cart = context.read<Cart>();
    final api = context.read<ApiService>();
    if (cart.isEmpty) return;

    if (!api.isLoggedIn) {
      context.read<TabNotifier>().goTo(4);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Connectez-vous pour valider votre commande.')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      final order = await api.createOrder(
        cart.toOrderLines(),
        paymentMethod: _method,
      );

      if (_method == 'online') {
        final url = await api.getPaymentLink(order.orderId);
        cart.clear();
        if (!mounted) return;
        final sessionId = api.sessionId;
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => _PaymentWebScreen(
              url: url,
              orderName: order.name,
              sessionId: sessionId,
            ),
          ),
        );
        if (!mounted) return;
        if (result == true) {
          _showResult('Paiement réussi',
              'Commande ${order.name} payée avec succès.\nTotal : ${AppFormat.money(order.amountTotal)}');
        } else if (result == false) {
          _showResult('Paiement annulé',
              'Le paiement pour la commande ${order.name} a été annulé ou refusé.');
        }
      } else {
        cart.clear();
        if (!mounted) return;
        _showResult(
          'Commande confirmée',
          'Référence : ${order.name}\nTotal : ${AppFormat.money(order.amountTotal)}\nPaiement à la livraison.',
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isAuthError) {
        _redirectToLogin();
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _redirectToLogin() {
    context.read<TabNotifier>().goTo(4);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Session expirée. Veuillez vous reconnecter.')),
    );
  }

  void _showResult(String title, String body) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<Cart>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Panier',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (cart.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('Votre panier est vide.',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
              )
            else ...[
              Expanded(
                child: ListView.separated(
                  itemCount: cart.lines.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final l = cart.lines[i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          ProductCover(
                              productId: l.productId,
                              width: 48,
                              height: 60,
                              radius: 10,
                              size: 128),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text(AppFormat.money(l.price),
                                    style: const TextStyle(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          _QtyStepper(line: l),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              _PaymentSelector(
                method: _method,
                onChanged: (m) => setState(() => _method = m),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontSize: 18)),
                  Text(AppFormat.money(cart.total),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _sending ? null : _validate,
                    child: _sending
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Valider la commande'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Écran WebView intégré pour le paiement en ligne (CMI / portail Odoo).
class _PaymentWebScreen extends StatefulWidget {
  final String url;
  final String orderName;
  final String sessionId;
  const _PaymentWebScreen({required this.url, required this.orderName, required this.sessionId});

  @override
  State<_PaymentWebScreen> createState() => _PaymentWebScreenState();
}

class _PaymentWebScreenState extends State<_PaymentWebScreen> {
  late final WebViewController _ctrl;
  bool _loading = true;

  static const _allowedHosts = [
    'cmi.co.ma',
    'paiement.cmi.co.ma',
  ];

  @override
  void initState() {
    super.initState();
    final baseHost = Uri.parse(AppConfig.baseUrl).host;
    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (url) {
          setState(() => _loading = false);
          _handleReturn(url);
        },
        onNavigationRequest: (req) {
          final host = Uri.parse(req.url).host;
          // Autoriser : serveur Odoo (baseHost + localhost) + passerelle CMI
          if (host == baseHost ||
              host == 'localhost' ||
              _allowedHosts.any((h) => host.endsWith(h))) {
            return NavigationDecision.navigate;
          }
          return NavigationDecision.prevent;
        },
      ));

    // Autoriser mixed content HTTPS→HTTP (okUrl/failUrl CMI en dev HTTP)
    if (_ctrl.platform is AndroidWebViewController) {
      (_ctrl.platform as AndroidWebViewController)
          .setMixedContentMode(MixedContentMode.alwaysAllow);
    }

    _loadWithCookie();
  }

  Future<void> _loadWithCookie() async {
    if (widget.sessionId.isNotEmpty) {
      final cookieManager = WebViewCookieManager();
      final uri = Uri.parse(widget.url);
      await cookieManager.setCookie(WebViewCookie(
        name: 'session_id',
        value: widget.sessionId,
        domain: uri.host,
        path: '/',
      ));
    }
    await _ctrl.loadRequest(Uri.parse(widget.url));
  }

  void _handleReturn(String url) {
    if (url.contains('/payment/status') ||
        url.contains('/shop/confirmation') ||
        url.contains('/payment/cmi/return')) {
      if (mounted) Navigator.of(context).pop(true);
    } else if (url.contains('/payment/cmi/error') ||
        url.contains('/payment/cancel')) {
      if (mounted) Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paiement — ${widget.orderName}'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _ctrl),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final CartLine line;
  const _QtyStepper({required this.line});
  @override
  Widget build(BuildContext context) {
    final cart = context.read<Cart>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn(Icons.remove_rounded,
            () => cart.setQuantity(line.productId, line.quantity - 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(line.quantity.toStringAsFixed(0),
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        _btn(Icons.add_rounded,
            () => cart.setQuantity(line.productId, line.quantity + 1)),
      ],
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.cardSoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }
}

class _PaymentSelector extends StatelessWidget {
  final String method;
  final ValueChanged<String> onChanged;
  const _PaymentSelector({required this.method, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _opt('cod', 'À la livraison', Icons.local_shipping_rounded),
        const SizedBox(width: 12),
        _opt('online', 'En ligne', Icons.credit_card_rounded),
      ],
    );
  }

  Widget _opt(String value, String label, IconData icon) {
    final active = method == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? AppColors.accent2 : AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? AppColors.accent2 : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: active ? Colors.white : AppColors.textMuted,
                  size: 22),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: active ? Colors.white : AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
