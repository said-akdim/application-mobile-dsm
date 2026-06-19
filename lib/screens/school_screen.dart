import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/nav_card.dart';
import 'level_screen.dart';

class SchoolScreen extends StatelessWidget {
  final City city;
  const SchoolScreen({super.key, required this.city});

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiService>();
    return Scaffold(
      appBar: AppBar(title: Text(city.name)),
      body: FutureBuilder<List<School>>(
        future: api.getSchools(city.id),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
                child: Text('Erreur : ${snap.error}',
                    style: const TextStyle(color: AppColors.textMuted)));
          }
          final schools = snap.data ?? [];
          if (schools.isEmpty) {
            return const Center(
                child: Text('Aucune école dans cette ville.',
                    style: TextStyle(color: AppColors.textMuted)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: schools.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final s = schools[i];
              return NavCard(
                icon: Icons.school_rounded,
                label: s.name,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => LevelScreen(school: s)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
