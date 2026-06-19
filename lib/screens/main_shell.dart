import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import '../state/cart.dart';
import 'home_screen.dart';
import 'products_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  // 0 Accueil · 1 Commandes · 2 Catalogue (centre) · 3 Panier · 4 Profil
  final _pages = const [
    HomeScreen(),
    OrdersScreen(),
    ProductsScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: _BottomBar(
        index: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _BottomBar({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<Cart>().count;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgDarker,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _item(Icons.home_rounded, 'Accueil', 0),
              _item(Icons.receipt_long_rounded, 'Commandes', 1),
              _center(context),
              _item(Icons.shopping_cart_rounded, 'Panier', 3, badge: cartCount),
              _item(Icons.person_rounded, 'Profil', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(IconData icon, String label, int i, {int badge = 0}) {
    final active = index == i;
    final color = active ? AppColors.accent : AppColors.textMuted;
    return InkWell(
      onTap: () => onTap(i),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 24),
                if (badge > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text('$badge',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _center(BuildContext context) {
    final active = index == 2;
    return GestureDetector(
      onTap: () => onTap(2),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: active ? AppColors.accent : AppColors.accent2,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (active ? AppColors.accent : AppColors.accent2)
                  .withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.search_rounded, color: Colors.white, size: 26),
      ),
    );
  }
}
