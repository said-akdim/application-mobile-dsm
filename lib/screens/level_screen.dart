import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/nav_card.dart';
import 'booklist_screen.dart';

class LevelScreen extends StatelessWidget {
  final School school;
  const LevelScreen({super.key, required this.school});

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiService>();
    return Scaffold(
      appBar: AppBar(title: Text(school.name)),
      body: FutureBuilder<List<Level>>(
        future: api.getLevels(school.id),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
                child: Text('Erreur : ${snap.error}',
                    style: const TextStyle(color: AppColors.textMuted)));
          }
          final levels = snap.data ?? [];
          if (levels.isEmpty) {
            return const Center(
                child: Text('Aucun niveau disponible pour cette école.',
                    style: TextStyle(color: AppColors.textMuted)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: levels.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final lv = levels[i];
              return NavCard(
                icon: Icons.grade_rounded,
                label: lv.name,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BooklistScreen(school: school, level: lv),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
