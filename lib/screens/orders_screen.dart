import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../state/tab_notifier.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  Future<List<OrderSummary>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final api = context.read<ApiService>();
    if (api.isLoggedIn && _future == null) {
      _future = api.getOrders();
    }
  }

  void _reload() {
    setState(() {
      _future = context.read<ApiService>().getOrders();
    });
  }

  String _label(String s) {
    switch (s) {
      case 'draft':
        return 'Devis';
      case 'sent':
        return 'Devis envoyé';
      case 'sale':
        return 'Confirmée';
      case 'done':
        return 'Terminée';
      case 'cancel':
        return 'Annulée';
      default:
        return s;
    }
  }

  Color _color(String s) {
    switch (s) {
      case 'sale':
      case 'done':
        return const Color(0xFF3DD68C);
      case 'cancel':
        return AppColors.accent;
      default:
        return AppColors.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = context.watch<ApiService>();

    if (!api.isLoggedIn) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.receipt_long_rounded,
                    size: 64, color: AppColors.textMuted),
                const SizedBox(height: 20),
                const Text(
                  'Connectez-vous pour voir vos commandes',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Votre historique de commandes sera disponible après connexion.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: () => context.read<TabNotifier>().goTo(4),
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Se connecter'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Si on vient de se connecter, charger les commandes
    _future ??= api.getOrders();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mes commandes',
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _reload,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<OrderSummary>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(
                        child: Text('Erreur : ${snap.error}',
                            style: const TextStyle(
                                color: AppColors.textMuted)));
                  }
                  final orders = snap.data ?? [];
                  if (orders.isEmpty) {
                    return const Center(
                        child: Text('Aucune commande.',
                            style:
                                TextStyle(color: AppColors.textMuted)));
                  }
                  return ListView.separated(
                    itemCount: orders.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final o = orders[i];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(o.name,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _color(o.state)
                                          .withValues(alpha: 0.18),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(_label(o.state),
                                        style: TextStyle(
                                            color: _color(o.state),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ),
                            Text(AppFormat.money(o.amountTotal),
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
