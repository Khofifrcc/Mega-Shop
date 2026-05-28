import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/state/cart_state.dart';
import '../../../../shared/widgets/mega_bottom_nav.dart';
import '../../../home/domain/entities/product.dart';

/// Search page with recent search chips and a 2-column results grid.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchCtrl = TextEditingController(text: 'Jacket');
  final _focusNode = FocusNode();
  final List<String> _recentSearches = ['Streetwear', 'Sneakers 2024', 'Oversized Hoodie'];

  final List<Product> _results = [
    const Product(
      id: 's1', name: 'Urban Leather Jacket', brand: 'Brand X',
      price: 129, badge: 'SALE',
      imageUrl: 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=400&q=80',
    ),
    const Product(
      id: 's2', name: 'Tech Windbreaker', brand: 'Aero Wear',
      price: 89,
      imageUrl: 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=400&q=80',
    ),
    const Product(
      id: 's3', name: 'Classic Denim', brand: 'Vintage Co.',
      price: 110, badge: 'NEW',
      imageUrl: 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=400&q=80',
    ),
    const Product(
      id: 's4', name: 'Puffer Jacket V2', brand: 'Alpine',
      price: 145,
      imageUrl: 'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?w=400&q=80',
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leadingWidth: 40,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
          padding: EdgeInsets.zero,
        ),
        title: _SearchBar(
          controller: _searchCtrl,
          focusNode: _focusNode,
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.tune_rounded,
                color: AppColors.textPrimary),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recent searches
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Searches',
                    style: AppTextStyles.productName.copyWith(fontSize: 15)),
                GestureDetector(
                  onTap: () => setState(() => _recentSearches.clear()),
                  child: Text('CLEAR',
                      style: AppTextStyles.buttonOutlined
                          .copyWith(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches
                  .map((s) => _RecentChip(
                        label: s,
                        onRemove: () =>
                            setState(() => _recentSearches.remove(s)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            Text('Hasil Cari',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 18)),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.68,
              ),
              itemCount: _results.length,
              itemBuilder: (context, i) => _SearchProductCard(
                product: _results[i],
                onAddToCart: () {
                  CartStateProvider.of(context).addItem(
                    productId: _results[i].id,
                    name: _results[i].name,
                    variant: 'Default',
                    price: _results[i].price,
                    imageUrl: _results[i].imageUrl,
                  );
                },
                onTap: () => Navigator.pushNamed(context, '/product',
                    arguments: _results[i]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: MegaBottomNav(
        currentIndex: 0,
        onTap: (i) {
          switch (i) {
            case 1:
              Navigator.pushReplacementNamed(context, '/reels');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/post');
              break;
            case 3:
              Navigator.pushNamed(context, '/cart');
              break;
            case 4:
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const _SearchBar({required this.controller, required this.focusNode});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        hintText: 'Search products...',
        hintStyle: AppTextStyles.brandName,
        prefixIcon: const Icon(Icons.search_rounded,
            color: AppColors.iconMuted, size: 20),
        suffixIcon: IconButton(
          onPressed: () => controller.clear(),
          icon: const Icon(Icons.cancel_rounded,
              color: AppColors.iconMuted, size: 18),
        ),
        filled: true,
        fillColor: AppColors.primarySurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }
}

class _RecentChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _RecentChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.history_rounded,
              size: 14, color: AppColors.iconMuted),
          const SizedBox(width: 6),
          Text(label,
              style: AppTextStyles.brandName.copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}

class _SearchProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAddToCart;
  final VoidCallback onTap;

  const _SearchProductCard(
      {required this.product,
      required this.onAddToCart,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) =>
                          Container(color: AppColors.primarySurface),
                      errorWidget: (ctx, url, err) =>
                          Container(color: AppColors.primarySurface),
                    ),
                  ),
                ),
                if (product.badge != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: product.badge == 'SALE'
                            ? AppColors.badgeSale
                            : AppColors.badgeNew,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(product.badge!,
                          style: AppTextStyles.badge),
                    ),
                  ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                        color: AppColors.surface.withAlpha(220),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.favorite_border_rounded,
                        size: 14, color: AppColors.iconMuted),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: AppTextStyles.productName
                          .copyWith(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(product.brand, style: AppTextStyles.brandName),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('\$${product.price.toStringAsFixed(0)}',
                          style:
                              AppTextStyles.price.copyWith(fontSize: 16)),
                      GestureDetector(
                        onTap: onAddToCart,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
