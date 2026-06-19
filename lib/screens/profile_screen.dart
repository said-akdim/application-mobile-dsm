import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import '../services/api_service.dart';
import '../state/cart.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiService>();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          const Text('Profil',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.accent2,
                  child: Icon(Icons.person, color: Colors.white, size: 48),
                ),
                const SizedBox(height: 14),
                Text(api.userName.isEmpty ? 'Client' : api.userName,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _tile(Icons.receipt_long_rounded, 'Mes commandes'),
          _tile(Icons.location_on_rounded, 'Adresses de livraison'),
          _tile(Icons.help_outline_rounded, 'Aide & support'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.card,
                foregroundColor: AppColors.accent,
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Se déconnecter'),
              onPressed: () {
                api.logout();
                context.read<Cart>().clear();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textPrimary),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppColors.textMuted),
        onTap: () {},
      ),
    );
  }
}
