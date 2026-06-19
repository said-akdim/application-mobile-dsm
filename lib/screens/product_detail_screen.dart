import 'package:flutter/material.dart';
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
            // En-tête : retour + visuel + infos
            Container(
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
                      ProductCover(
                          productId: product.productId,
                          width: 130,
                          height: 180,
                          size: 512),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.name,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Text(AppFormat.money(product.price),
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accent)),
                            const SizedBox(height: 10),
                            Text(
                              product.qtyAvailable > 0
                                  ? 'En stock : ${product.qtyAvailable.toStringAsFixed(0)}'
                                  : 'Sur commande',
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: const Text('Ajouter au panier'),
                  onPressed: () {
                    context.read<Cart>().add(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.name} ajouté au panier'),
                        duration: const Duration(milliseconds: 900),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
