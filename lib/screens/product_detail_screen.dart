import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../theme.dart';
import '../models/models.dart';
import '../state/cart.dart';
import '../widgets/product_cover.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // En-tête avec couverture
                  SliverToBoxAdapter(child: _Header(product: product)),
                  // Résumé
                  if (product.summary != null && product.summary!.isNotEmpty)
                    SliverToBoxAdapter(
                        child: _Section(
                            title: 'Résumé',
                            child: Text(product.summary!,
                                style: const TextStyle(
                                    height: 1.6,
                                    color: AppColors.textPrimary)))),
                  // Fiche technique
                  SliverToBoxAdapter(child: _TechSheet(product: product)),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                ],
              ),
            ),
            // Bouton panier
            _AddToCartBar(product: product),
          ],
        ),
      ),
    );
  }
}

// ── En-tête ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final Product product;
  const _Header({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.bgDarker,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Couverture
              ProductCover(
                  productId: product.productId,
                  width: 130,
                  height: 185,
                  radius: 12,
                  size: 512),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.isNew)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent2,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Nouveauté',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                    Text(product.name,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                    if (product.authors != null) ...[
                      const SizedBox(height: 6),
                      Text(product.authors!,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                              fontStyle: FontStyle.italic)),
                    ],
                    if (product.editor != null) ...[
                      const SizedBox(height: 4),
                      Text(product.editor!,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ],
                    const SizedBox(height: 12),
                    Text(AppFormat.money(product.price),
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent)),
                    const SizedBox(height: 8),
                    _StockBadge(qty: product.qtyAvailable),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final double qty;
  const _StockBadge({required this.qty});

  @override
  Widget build(BuildContext context) {
    final inStock = qty > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (inStock ? const Color(0xFF3DD68C) : AppColors.star)
            .withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            inStock
                ? Icons.check_circle_outline_rounded
                : Icons.access_time_rounded,
            size: 13,
            color:
                inStock ? const Color(0xFF3DD68C) : AppColors.star,
          ),
          const SizedBox(width: 4),
          Text(
            inStock
                ? 'En stock (${qty.toStringAsFixed(0)})'
                : 'Sur commande',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: inStock
                    ? const Color(0xFF3DD68C)
                    : AppColors.star),
          ),
        ],
      ),
    );
  }
}

// ── Fiche technique ───────────────────────────────────────────────────────────

class _TechSheet extends StatelessWidget {
  final Product product;
  const _TechSheet({required this.product});

  @override
  Widget build(BuildContext context) {
    final rows = <_InfoRow>[];

    if (product.isbn != null)
      rows.add(_InfoRow(
          icon: Icons.qr_code_rounded,
          label: 'EAN-13 / ISBN',
          value: product.isbn!,
          copyable: true));
    if (product.category != null)
      rows.add(_InfoRow(
          icon: Icons.category_outlined,
          label: 'Thème / Catégorie',
          value: product.category!));
    if (product.editionYear != null)
      rows.add(_InfoRow(
          icon: Icons.calendar_today_outlined,
          label: 'Année d\'édition',
          value: product.editionYear!));
    if (product.collection != null)
      rows.add(_InfoRow(
          icon: Icons.collections_bookmark_outlined,
          label: 'Collection',
          value: product.collection!));
    if (product.language != null)
      rows.add(_InfoRow(
          icon: Icons.translate_rounded,
          label: 'Langue',
          value: product.language!));
    if (product.pageCount != null)
      rows.add(_InfoRow(
          icon: Icons.auto_stories_outlined,
          label: 'Pages',
          value: '${product.pageCount}'));
    if (product.weight != null)
      rows.add(_InfoRow(
          icon: Icons.scale_outlined,
          label: 'Poids',
          value: '${product.weight!.toStringAsFixed(0)} g'));
    if (product.dimensions != null)
      rows.add(_InfoRow(
          icon: Icons.straighten_rounded,
          label: 'Dimensions',
          value: product.dimensions!));

    if (rows.isEmpty) return const SizedBox.shrink();

    return _Section(
      title: 'Fiche technique',
      child: Column(children: rows),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool copyable;
  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.copyable = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(value,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                    ),
                    if (copyable)
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: value));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Copié !'),
                                duration: Duration(milliseconds: 800)),
                          );
                        },
                        child: const Icon(Icons.copy_rounded,
                            size: 16, color: AppColors.textMuted),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ── Barre panier ──────────────────────────────────────────────────────────────

class _AddToCartBar extends StatelessWidget {
  final Product product;
  const _AddToCartBar({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.add_shopping_cart_rounded),
                label: const Text('Ajouter au panier'),
                onPressed: () {
                  context.read<Cart>().add(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '${product.name.split(']').last.trim()} ajouté'),
                      duration: const Duration(milliseconds: 900),
                    ),
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
