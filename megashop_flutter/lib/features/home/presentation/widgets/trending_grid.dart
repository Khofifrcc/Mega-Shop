import 'package:flutter/material.dart';
import '../../domain/entities/product.dart';
import 'product_card.dart';

/// Responsive 2-column (phone) / 3-column (tablet) grid of [ProductCard]s.
///
/// Cross-axis count adapts based on screen width so the grid looks good on
/// any device without manual breakpoints.
class TrendingGrid extends StatelessWidget {
  final List<Product> products;
  final Function(Product)? onAddToCart;
  final Function(Product)? onBuyNow;
  final Function(Product, bool)? onFavoriteToggle;
  final Function(Product)? onProductTap;
  final Function(Product)? onEdit;
  final Function(Product)? onDelete;

  const TrendingGrid({
    super.key,
    required this.products,
    this.onAddToCart,
    this.onBuyNow,
    this.onFavoriteToggle,
    this.onProductTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // 2 columns on phones (< 600px), 3 on tablets
    final crossAxisCount = screenWidth >= 600 ? 3 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        // Taller ratio to accommodate product info below image
        childAspectRatio: 0.58,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => onProductTap?.call(product),
            child: ProductCard(
              product: product,
              onAddToCart: () => onAddToCart?.call(product),
              onBuyNow: () => onBuyNow?.call(product),
              onFavoriteToggle: (val) => onFavoriteToggle?.call(product, val),
              onEdit: () => onEdit?.call(product),
              onDelete: () => onDelete?.call(product),
            ),
          ),
        );
      },
    );
  }
}
