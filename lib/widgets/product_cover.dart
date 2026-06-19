import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../theme.dart';
import '../services/api_service.dart';

/// Couverture/photo d'un produit Odoo, avec cookie de session et repli.
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        AppFormat.productImage(productId, size: size),
        width: width,
        height: height,
        fit: BoxFit.cover,
        headers: headers,
        errorBuilder: (_, __, ___) => _placeholder(),
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _placeholder(loading: true),
      ),
    );
  }

  Widget _placeholder({bool loading = false}) => Container(
        width: width,
        height: height,
        color: AppColors.cardSoft,
        child: Icon(
          loading ? Icons.hourglass_empty_rounded : Icons.menu_book_rounded,
          color: AppColors.textMuted,
          size: width < 80 ? 20 : 40,
        ),
      );
}
