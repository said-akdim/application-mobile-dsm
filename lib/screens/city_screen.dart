import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/nav_card.dart';
import 'school_screen.dart';

class CityScreen extends StatelessWidget {
  const CityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Choisir la ville')),
      body: FutureBuilder<List<City>>(
        future: api.getCities(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
                child: Text('Erreur : ${snap.error}',
                    style: const TextStyle(color: AppColors.textMuted)));
          }
          final cities = snap.data ?? [];
          if (cities.isEmpty) {
            return const Center(
                child: Text('Aucune ville disponible.',
                    style: TextStyle(color: AppColors.textMuted)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: cities.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final c = cities[i];
              return NavCard(
                icon: Icons.location_city_rounded,
                label: c.name,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SchoolScreen(city: c)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
