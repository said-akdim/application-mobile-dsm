import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../theme.dart';
import '../services/api_service.dart';

/// Couverture d'un livre avec cache, session Odoo et placeholder livre.
class ProductCover extends StatelessWidget {
  final int productId;
  final double width;
  final double height;
  final double radius;
  final int size;
  const ProductCover({
    super.key,
    required this.productId,
    required this.width,
    required this.height,
    this.radius = 16,
    this.size = 256,
  });

  @override
  Widget build(BuildContext context) {
    final headers = context.read<ApiService>().imageHeaders;
    final url = AppFormat.productImage(productId, size: size);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: url,
        httpHeaders: headers,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (_, __) =>
            _BookPlaceholder(width: width, height: height, loading: true),
        errorWidget: (_, __, ___) =>
            _BookPlaceholder(width: width, height: height),
      ),
    );
  }
}

class _BookPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final bool loading;
  const _BookPlaceholder(
      {required this.width, required this.height, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cardSoft, AppColors.card],
        ),
      ),
      child: loading
          ? const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.textMuted),
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu_book_rounded,
                    color: AppColors.textMuted.withValues(alpha: 0.4),
                    size: width < 80 ? 22 : 48),
                if (width >= 100) ...[
                  const SizedBox(height: 8),
                  Text('Pas d\'image',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted.withValues(alpha: 0.5))),
                ],
              ],
            ),
    );
  }
}
