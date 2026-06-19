import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../state/cart.dart';
import '../widgets/product_cover.dart';

class BooklistScreen extends StatefulWidget {
  final School school;
  final Level level;
  const BooklistScreen({super.key, required this.school, required this.level});

  @override
  State<BooklistScreen> createState() => _BooklistScreenState();
}

class _BooklistScreenState extends State<BooklistScreen> {
  late Future<List<Product>> _future;
  final Set<int> _selected = {};
  bool _initSelection = false;

  @override
  void initState() {
    super.initState();
    _future = context
        .read<ApiService>()
        .getBooklist(widget.school.id, widget.level.id);
  }

  void _addToCart(List<Product> items) {
    final cart = context.read<Cart>();
    for (final p in items.where((p) => _selected.contains(p.productId))) {
      cart.add(p, quantity: p.quantity);
    }
    Navigator.of(context).popUntil((r) => r.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_selected.length} manuel(s) ajouté(s) au panier')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.level.name} — manuels')),
      body: FutureBuilder<List<Product>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
                child: Text('Erreur : ${snap.error}',
                    style: const TextStyle(color: AppColors.textMuted)));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(
                child: Text('Liste vide.',
                    style: TextStyle(color: AppColors.textMuted)));
          }

          if (!_initSelection) {
            for (final p in items) {
              if (p.mandatory) _selected.add(p.productId);
            }
            _initSelection = true;
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final p = items[i];
                    final checked = _selected.contains(p.productId);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (checked) {
                          _selected.remove(p.productId);
                        } else {
                          _selected.add(p.productId);
                        }
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: checked
                                ? AppColors.accent2
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            ProductCover(
                                productId: p.productId,
                                width: 48,
                                height: 60,
                                radius: 10,
                                size: 128),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(AppFormat.money(p.price),
                                          style: const TextStyle(
                                              color: AppColors.accent,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13)),
                                      if (p.mandatory) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.star
                                                .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: const Text('Obligatoire',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: AppColors.star)),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              checked
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              color: checked
                                  ? AppColors.accent2
                                  : AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.add_shopping_cart_rounded),
                      label: Text('Ajouter (${_selected.length}) au panier'),
                      onPressed:
                          _selected.isEmpty ? null : () => _addToCart(items),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
