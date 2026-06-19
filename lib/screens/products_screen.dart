import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../state/cart.dart';
import 'product_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late Future<List<Product>> _future;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = context.read<ApiService>().getProducts();
  }

  void _reload() {
    setState(() {
      _future = context.read<ApiService>().getProducts(search: _search.text);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalogue',
            style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: Navigator.of(context).canPop(),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Rechercher un manuel, un produit\u2026',
                prefixIcon:
                    const Icon(Icons.search_rounded, color: AppColors.textMuted),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune_rounded,
                      color: AppColors.textMuted),
                  onPressed: _reload,
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _reload(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Product>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(
                        child: Text('Erreur : ${snap.error}',
                            style:
                                const TextStyle(color: AppColors.textMuted)));
                  }
                  final items = snap.data ?? [];
                  if (items.isEmpty) {
                    return const Center(
                        child: Text('Aucun produit.',
                            style: TextStyle(color: AppColors.textMuted)));
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.58,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, i) =>
                        _ProductGridCard(product: items[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  final Product product;
  const _ProductGridCard({required this.product});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: Image.network(
                      AppFormat.productImage(product.productId),
                      fit: BoxFit.cover,
                      headers: context.read<ApiService>().imageHeaders,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.cardSoft,
                        child: const Icon(Icons.menu_book_rounded,
                            color: AppColors.textMuted, size: 40),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: GestureDetector(
                      onTap: () {
                        context.read<Cart>().add(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} ajouté'),
                            duration: const Duration(milliseconds: 800),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(AppFormat.money(product.price),
              style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
