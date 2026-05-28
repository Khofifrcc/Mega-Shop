import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/state/cart_state.dart';
import '../../../home/domain/entities/product.dart';

/// Product Detail page matching the mockup.
///
/// Accepts a [Product] as a route argument via [ModalRoute.of(context)!.settings.arguments].
/// Features: full-width hero image, seller info card, expandable description,
/// and sticky "Add to Cart" + "Buy Now" buttons.
class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _imageIndex = 0;
  bool _isExpanded = false;
  bool _isFavorite = false;
  bool _isFollowing = false;

  // Mock extra images
  final List<String> _extraImages = [
    'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600&q=80',
    'https://images.unsplash.com/photo-1522312346375-d1a52e2b99b3?w=600&q=80',
    'https://images.unsplash.com/photo-1434056886845-dac89ffe9b56?w=600&q=80',
  ];

  static const _description =
      'Experience the future on your wrist with the Aura Titanium Series X. '
      'Forged from aerospace-grade titanium, it offers unparalleled durability '
      'without compromising on its feather-light feel. Features advanced biometric '
      'tracking, 14-day battery life, and an edge-to-edge sapphire crystal display.';

  @override
  Widget build(BuildContext context) {
    // Accept either a passed Product or fall back to a mock
    final product = (ModalRoute.of(context)?.settings.arguments is Product)
        ? ModalRoute.of(context)!.settings.arguments as Product
        : _mockProduct;

    final images = [product.imageUrl, ..._extraImages.take(2)];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // ── Hero image ─────────────────────────────────────────────
                _HeroImageSection(
                  images: images,
                  currentIndex: _imageIndex,
                  isFavorite: _isFavorite,
                  onIndexChanged: (i) => setState(() => _imageIndex = i),
                  onBack: () => Navigator.pop(context),
                  onShare: () {},
                  onFavorite: () =>
                      setState(() => _isFavorite = !_isFavorite),
                ),
                // ── Info sheet ─────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + price
                      Text(product.name,
                          style: AppTextStyles.sectionTitle
                              .copyWith(fontSize: 22)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: AppTextStyles.price.copyWith(fontSize: 22),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('Free Shipping',
                                style: AppTextStyles.brandName.copyWith(
                                    color: AppColors.primary, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Seller card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                                color: AppColors.shadow,
                                blurRadius: 8,
                                offset: Offset(0, 2))
                          ],
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 24,
                              backgroundImage: NetworkImage(
                                  'https://images.unsplash.com/photo-1527980965255-d3b416303d12?w=100&q=80'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('TechHaven Official',
                                      style: AppTextStyles.productName),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          color: AppColors.accent, size: 14),
                                      const SizedBox(width: 4),
                                      Text('4.9 (1.2k reviews)',
                                          style: AppTextStyles.brandName),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _isFollowing = !_isFollowing),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _isFollowing
                                      ? AppColors.primarySurface
                                      : AppColors.primarySurface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: AppColors.primary, width: 1.5),
                                ),
                                child: Text(
                                  _isFollowing ? 'Following' : 'Follow',
                                  style: AppTextStyles.buttonOutlined
                                      .copyWith(fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('Product Details',
                          style: AppTextStyles.sectionTitle.copyWith(
                              fontSize: 17)),
                      const SizedBox(height: 8),
                      Text(
                        _isExpanded
                            ? _description
                            : '${_description.substring(0, 120)}...',
                        style: AppTextStyles.brandName
                            .copyWith(fontSize: 13, height: 1.6),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _isExpanded = !_isExpanded),
                        child: Text(
                          _isExpanded ? 'Show less' : 'Read more',
                          style: AppTextStyles.buttonOutlined
                              .copyWith(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Sticky bottom bar ─────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
              color: AppColors.background,
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          CartStateProvider.of(context).addItem(
                            productId: product.id,
                            name: product.name,
                            variant: 'Default',
                            price: product.price,
                            imageUrl: product.imageUrl,
                          );
                          Navigator.pushNamed(context, '/cart');
                        },
                        icon: const Icon(Icons.shopping_cart_outlined,
                            size: 18),
                        label: Text('Add to Cart',
                            style: AppTextStyles.buttonOutlined),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/checkout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28)),
                          elevation: 0,
                        ),
                        child: Text('Buy Now',
                            style: AppTextStyles.buttonFilled
                                .copyWith(fontSize: 15)),
                      ),
                    ),
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

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _HeroImageSection extends StatelessWidget {
  final List<String> images;
  final int currentIndex;
  final bool isFavorite;
  final ValueChanged<int> onIndexChanged;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onFavorite;

  const _HeroImageSection({
    required this.images,
    required this.currentIndex,
    required this.isFavorite,
    required this.onIndexChanged,
    required this.onBack,
    required this.onShare,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.42,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: images.length,
            onPageChanged: onIndexChanged,
            itemBuilder: (_, i) => CachedNetworkImage(
              imageUrl: images[i],
              fit: BoxFit.cover,
              placeholder: (ctx, url) =>
                  Container(color: AppColors.primarySurface),
              errorWidget: (ctx, url, err) =>
                  Container(color: AppColors.primarySurface),
            ),
          ),
          // Dots
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: i == currentIndex ? 20 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: i == currentIndex
                      ? AppColors.surface
                      : Colors.white54,
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
            ),
          ),
          // Back / share / heart
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleIconBtn(icon: Icons.arrow_back_rounded, onTap: onBack),
                  Row(
                    children: [
                      _CircleIconBtn(icon: Icons.share_outlined, onTap: onShare),
                      const SizedBox(width: 8),
                      _CircleIconBtn(
                        icon: isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        iconColor: isFavorite
                            ? AppColors.badgeSale
                            : AppColors.iconDefault,
                        onTap: onFavorite,
                      ),
                    ],
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

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _CircleIconBtn({
    required this.icon,
    this.iconColor = AppColors.iconDefault,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface.withAlpha(210),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}

final _mockProduct = Product(
  id: 'mock_detail',
  name: 'Aura Titanium Smartwatch Series X',
  brand: 'TechHaven Official',
  price: 299.00,
  imageUrl:
      'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600&q=80',
);
