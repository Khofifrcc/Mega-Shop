import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/product.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Reusable product card displayed in the 2-column trending grid.
///
/// Anatomy (top → bottom):
///   • Hero image with optional badge (NEW / SALE) and favourite toggle
///   • Brand name row (avatar dot + label)
///   • Product name (up to 2 lines)
///   • Price + optional strikethrough original price
///   • "Add to Cart" (outlined) and "Buy Now" (filled amber) buttons
class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onAddToCart;
  final VoidCallback? onBuyNow;
  final ValueChanged<bool>? onFavoriteToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProductCard({
    super.key,
    required this.product,
    this.onAddToCart,
    this.onBuyNow,
    this.onFavoriteToggle,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  late bool _isFavorite;
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.product.isFavorite;
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.8,
      upperBound: 1.0,
      value: 1.0,
    );
    _heartScale = _heartController;
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    widget.onFavoriteToggle?.call(_isFavorite);
    _heartController.reverse().then((_) => _heartController.forward());
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isMyProduct = widget.product.userId == currentUserId;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Consistent Image Area (aspect ratio locks height dynamically)
          AspectRatio(
            aspectRatio: 1.15,
            child: _ProductImage(
              product: widget.product,
              isFavorite: _isFavorite,
              heartScale: _heartScale,
              onFavoriteTap: _toggleFavorite,
            ),
          ),

          // Expanded Info Area (aligns buttons horizontally)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Brand
                      _BrandRow(brand: widget.product.brand),
                      const SizedBox(height: 3),
                      // Product name
                      Text(
                        widget.product.name,
                        style: AppTextStyles.productName.copyWith(fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Price row
                      _PriceRow(product: widget.product),
                    ],
                  ),
                  // Action buttons
                  isMyProduct
                      ? _OwnerButtons(
                          onEdit: widget.onEdit,
                          onDelete: widget.onDelete,
                        )
                      : _ActionButtons(
                          onAddToCart: widget.onAddToCart,
                          onBuyNow: widget.onBuyNow,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Private sub-widgets
// ────────────────────────────────────────────────────────────────────────────

class _ProductImage extends StatelessWidget {
  final Product product;
  final bool isFavorite;
  final Animation<double> heartScale;
  final VoidCallback onFavoriteTap;

  const _ProductImage({
    required this.product,
    required this.isFavorite,
    required this.heartScale,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final isVideoProduct = product.imageUrl.toLowerCase().contains('.mp4') ||
        product.imageUrl.toLowerCase().contains('.mov') ||
        product.imageUrl.toLowerCase().contains('.webm');
    return Stack(
      fit: StackFit.expand, // fills the Expanded parent
      children: [
        // Hero image / video preview
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: isVideoProduct
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: Colors.black87,
                    ),
                    const Center(
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                )
              : CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (ctx, url) => Container(
                    color: AppColors.primarySurface,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (ctx, url, err) => Container(
                    color: AppColors.primarySurface,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: AppColors.iconMuted,
                    ),
                  ),
                ),
        ),
        // Badge (NEW / SALE)
        if (product.badge != null)
          Positioned(
            top: 10,
            left: 10,
            child: _Badge(label: product.badge!),
          ),
        // Favourite button
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onFavoriteTap,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surface.withAlpha(230),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ScaleTransition(
                scale: heartScale,
                child: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFavorite ? AppColors.badgeSale : AppColors.iconMuted,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;

  const _Badge({required this.label});

  Color get _color {
    switch (label) {
      case 'NEW':
        return AppColors.badgeNew;
      case 'SALE':
        return AppColors.badgeSale;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: AppTextStyles.badge),
    );
  }
}

class _BrandRow extends StatelessWidget {
  final String brand;

  const _BrandRow({required this.brand});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 1.5),
            color: AppColors.primarySurface,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            brand,
            style: AppTextStyles.brandName,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final Product product;

  const _PriceRow({required this.product});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '\$${product.price.toStringAsFixed(2)}',
          style: AppTextStyles.price,
        ),
        if (product.isOnSale) ...[
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '\$${product.originalPrice!.toStringAsFixed(2)}',
              style: AppTextStyles.originalPrice,
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final VoidCallback? onAddToCart;
  final VoidCallback? onBuyNow;

  const _ActionButtons({this.onAddToCart, this.onBuyNow});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 34,
            child: OutlinedButton(
              onPressed: onAddToCart,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text('Add to Cart', style: AppTextStyles.buttonOutlined),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 34,
            child: ElevatedButton(
              onPressed: onBuyNow,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: AppColors.accent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text('Buy Now', style: AppTextStyles.buttonFilled),
            ),
          ),
        ),
      ],
    );
  }
}

class _OwnerButtons extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _OwnerButtons({this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 34,
            child: OutlinedButton(
              onPressed: onEdit,
              child: Text('Edit', style: AppTextStyles.buttonOutlined),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 34,
            child: ElevatedButton(
              onPressed: onDelete,
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }
}
