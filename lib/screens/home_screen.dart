import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'city_screen.dart';
import 'product_detail_screen.dart';
import 'products_screen.dart';
import '../widgets/product_cover.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Product>> _products;

  @override
  void initState() {
    super.initState();
    _products = _loadProducts();
  }

  Future<List<Product>> _loadProducts() async {
    final products =
        await context.read<ApiService>().getProducts(limit: 12);
    NotificationService.checkAndNotifyNewProducts(products);
    return products;
  }

  Future<void> _refresh() async {
    setState(() {
      _products = _loadProducts();
    });
    await _products;
  }

  @override
  Widget build(BuildContext context) {
    final name = context.watch<ApiService>().userName;
    final firstName = name.isNotEmpty ? name.split(' ').first : '';
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _Header(name: firstName),
          const SizedBox(height: 20),
          _SearchField(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProductsScreen()),
            ),
          ),
          const SizedBox(height: 24),
          _SchoolBanner(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CityScreen()),
            ),
          ),
          const SizedBox(height: 28),
          const _SectionTitle('Disponibles pour vous'),
          const SizedBox(height: 14),
          SizedBox(
            height: 250,
            child: FutureBuilder<List<Product>>(
              future: _products,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            color: AppColors.textMuted, size: 36),
                        const SizedBox(height: 8),
                        const Text('Impossible de charger les produits.',
                            style: TextStyle(color: AppColors.textMuted)),
                        TextButton(
                          onPressed: _refresh,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return const Center(
                      child: Text('Aucun produit.',
                          style: TextStyle(color: AppColors.textMuted)));
                }
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, i) => _BookCard(product: items[i]),
                );
              },
            ),
          ),
          // Footer Copyright DSM
          const SizedBox(height: 32),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '© Librairie DSM ${DateTime.now().year}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  const _Header({required this.name});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.accent2,
          child: Icon(Icons.person, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bonjour',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
              Text(
                name.isEmpty ? 'Bienvenue !' : '$name !',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            color: AppColors.textPrimary,
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchField({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.search_rounded, color: AppColors.textMuted),
            SizedBox(width: 12),
            Text('Rechercher un manuel, un produit…',
                style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _SchoolBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _SchoolBanner({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.accent2, Color(0xFF8A6CFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Commande scolaire',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('Ville \u2192 \u00e9cole \u2192 niveau \u2192 manuels',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.85), fontSize: 13)),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Commencer',
                        style: TextStyle(
                            color: AppColors.accent2,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.menu_book_rounded, color: Colors.white, size: 64),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }
}

class _BookCard extends StatelessWidget {
  final Product product;
  const _BookCard({required this.product});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product)),
      ),
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductCover(productId: product.productId, width: 140, height: 170),
            const SizedBox(height: 8),
            Text(product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(AppFormat.money(product.price),
                style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
