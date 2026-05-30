import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../home/domain/entities/product.dart';

/// Seller Shop Profile page — mirrors the user profile layout but
/// personalized for sellers: avatar ring, shop stats, seller-specific
/// info chips (response rate, joined date, total sales), Follow + Chat.
class SellerProfilePage extends StatefulWidget {
  const SellerProfilePage({super.key});

  @override
  State<SellerProfilePage> createState() => _SellerProfilePageState();
}

class _SellerProfilePageState extends State<SellerProfilePage>
    with SingleTickerProviderStateMixin {
  bool _isFollowing = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final seller = args is SellerArgs ? args : _mockSeller;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.textPrimary),
          ),
        ),
        title: Text('Shop Profile',
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 18)),
        centerTitle: true,
        actions: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.share_outlined,
                  color: AppColors.iconDefault),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppColors.iconDefault),
            ),
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(child: _buildHeader(seller)),
        ],
        body: Column(
          children: [
            // ── Tab bar ─────────────────────────────────────────────────
            Container(
              color: AppColors.surface,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                indicatorWeight: 2.5,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.iconMuted,
                labelStyle:
                    AppTextStyles.productName.copyWith(fontSize: 14),
                dividerColor: AppColors.divider,
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.grid_view_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Products'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star_outline_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Reviews'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Tab content ──────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Products tab — 2-column grid
                  GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: seller.products.length,
                    itemBuilder: (context, i) {
                      final p = seller.products[i];
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(
                              context, '/product',
                              arguments: p),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(
                                    color: AppColors.shadow,
                                    blurRadius: 6,
                                    offset: Offset(0, 2))
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AspectRatio(
                                  aspectRatio: 1.15,
                                  child: ClipRRect(
                                    borderRadius:
                                        const BorderRadius.vertical(
                                            top: Radius.circular(14)),
                                    child: CachedNetworkImage(
                                      imageUrl: p.imageUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      placeholder: (_, __) => Container(
                                          color: AppColors.primarySurface),
                                      errorWidget: (_, __, ___) =>
                                          Container(
                                              color:
                                                  AppColors.primarySurface),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(p.name,
                                                style: AppTextStyles.productName
                                                    .copyWith(fontSize: 12),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis),
                                            const SizedBox(height: 4),
                                            Text(
                                                '\$${p.price.toStringAsFixed(2)}',
                                                style: AppTextStyles.price
                                                    .copyWith(fontSize: 13)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Reviews tab
                  ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _mockReviews.length,
                    itemBuilder: (_, i) =>
                        _ReviewTile(review: _mockReviews[i]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(SellerArgs seller) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          // ── Avatar with gradient ring (same as profile_page) ──────────
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: seller.avatarUrl,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: AppColors.primarySurface),
                  errorWidget: (_, __, ___) =>
                      Container(color: AppColors.primarySurface),
                ),
              ),
              // Verified badge at bottom-right
              if (seller.isVerified)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.surface, width: 1.5),
                    ),
                    child: const Icon(Icons.verified_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Shop name + verified text ─────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(seller.name,
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 20)),
              if (seller.isVerified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified_rounded,
                    color: AppColors.primary, size: 18),
              ],
            ],
          ),
          const SizedBox(height: 4),

          // Tagline / shop description
          Text(
            seller.tagline,
            style:
                AppTextStyles.brandName.copyWith(fontSize: 13, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // ── Seller info chips (response rate, joined, sales) ──────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _InfoChip(
                  icon: Icons.reply_rounded,
                  label: '98% Response'),
              const SizedBox(width: 8),
              _InfoChip(
                  icon: Icons.calendar_today_rounded,
                  label: 'Since 2021'),
              const SizedBox(width: 8),
              _InfoChip(
                  icon: Icons.local_shipping_outlined,
                  label: '10K+ Sales'),
            ],
          ),
          const SizedBox(height: 18),

          // ── Stats row (same style as profile_page) ────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(
                  value: seller.productCount.toString(),
                  label: 'Products'),
              _Separator(),
              _StatItem(value: seller.followersStr, label: 'Followers'),
              _Separator(),
              _StatItem(
                  value: '${seller.rating}★', label: 'Rating'),
            ],
          ),
          const SizedBox(height: 16),

          // ── Follow + Chat buttons ─────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: ElevatedButton(
                    onPressed: () =>
                        setState(() => _isFollowing = !_isFollowing),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFollowing
                          ? AppColors.surface
                          : AppColors.primary,
                      foregroundColor: _isFollowing
                          ? AppColors.primary
                          : Colors.white,
                      side: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      _isFollowing ? 'Following ✓' : 'Follow',
                      style: AppTextStyles.buttonFilled.copyWith(
                        color: _isFollowing
                            ? AppColors.primary
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/chat',
                    arguments: {
                      'sellerId': seller.id,
                      'sellerName': seller.name,
                      'productId': '',
                      'productName': '',
                      'productImage': seller.avatarUrl,
                      'productPrice': 0.0,
                    },
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded,
                      size: 16),
                  label: Text('Chat',
                      style: AppTextStyles.buttonOutlined),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(
                        color: AppColors.divider, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider, height: 1),
        ],
      ),
    );
  }
}

// ── Info chip (response rate, join date, sales) ───────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.brandName.copyWith(
                  fontSize: 11, color: AppColors.primary)),
        ],
      ),
    );
  }
}

// ── Stat item (mirrors profile_page _StatItem) ────────────────────────────────

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.brandName),
      ],
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: AppColors.divider);
  }
}

// ── Review tile ───────────────────────────────────────────────────────────────

class _ReviewTile extends StatelessWidget {
  final _Review review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(review.avatarUrl),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(review.author,
                        style: AppTextStyles.productName
                            .copyWith(fontSize: 13)),
                    const Spacer(),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < review.rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: AppColors.accent,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(review.comment,
                    style: AppTextStyles.brandName
                        .copyWith(fontSize: 12, height: 1.5)),
                const SizedBox(height: 4),
                Text(review.date,
                    style: AppTextStyles.brandName.copyWith(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

class SellerArgs {
  final String id;
  final String name;
  final String tagline;
  final String avatarUrl;
  final String coverUrl;
  final bool isVerified;
  final int productCount;
  final String followersStr;
  final double rating;
  final List<Product> products;

  const SellerArgs({
    required this.id,
    required this.name,
    required this.tagline,
    required this.avatarUrl,
    required this.coverUrl,
    this.isVerified = true,
    required this.productCount,
    required this.followersStr,
    required this.rating,
    required this.products,
  });
}

class _Review {
  final String author;
  final String avatarUrl;
  final int rating;
  final String comment;
  final String date;

  const _Review({
    required this.author,
    required this.avatarUrl,
    required this.rating,
    required this.comment,
    required this.date,
  });
}

// ── Mock data ─────────────────────────────────────────────────────────────────

final _mockSeller = SellerArgs(
  id: 'techhaven',
  name: 'TechHaven Official',
  tagline: '🏆 Top Rated Seller · Premium Tech & Accessories',
  avatarUrl:
      'https://images.unsplash.com/photo-1527980965255-d3b416303d12?w=200&q=80',
  coverUrl:
      'https://images.unsplash.com/photo-1518770660439-4636190af475?w=800&q=80',
  isVerified: true,
  productCount: 128,
  followersStr: '24.5K',
  rating: 4.9,
  products: [
    const Product(
      id: 'p_s1',
      name: 'Minimalist Chrono Smart Watch Pro',
      brand: 'TechHaven',
      price: 149.99,
      imageUrl:
          'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400&q=80',
    ),
    const Product(
      id: 'p_s2',
      name: 'Aura Titanium Series X',
      brand: 'TechHaven',
      price: 299.00,
      imageUrl:
          'https://images.unsplash.com/photo-1434056886845-dac89ffe9b56?w=400&q=80',
    ),
    const Product(
      id: 'p_s3',
      name: 'Ultra Slim Wireless Earbuds',
      brand: 'TechHaven',
      price: 79.99,
      imageUrl:
          'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&q=80',
    ),
    const Product(
      id: 'p_s4',
      name: 'Portable MagSafe Charger 20W',
      brand: 'TechHaven',
      price: 49.00,
      imageUrl:
          'https://images.unsplash.com/photo-1609091839311-d5365f9ff1c5?w=400&q=80',
    ),
    const Product(
      id: 'p_s5',
      name: 'Smart Home Hub Pro',
      brand: 'TechHaven',
      price: 89.99,
      imageUrl:
          'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&q=80',
    ),
    const Product(
      id: 'p_s6',
      name: 'Mechanical Gaming Keyboard',
      brand: 'TechHaven',
      price: 129.00,
      imageUrl:
          'https://images.unsplash.com/photo-1541140532154-b024d705b90a?w=400&q=80',
    ),
  ],
);

final _mockReviews = [
  const _Review(
    author: 'Diana V.',
    avatarUrl:
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=80&q=80',
    rating: 5,
    comment:
        'Amazing quality! Shipped fast and packaging was premium. Will order again 🔥',
    date: '2 days ago',
  ),
  const _Review(
    author: 'Marcus T.',
    avatarUrl:
        'https://images.unsplash.com/photo-1527980965255-d3b416303d12?w=80&q=80',
    rating: 4,
    comment:
        'Great product, exactly as described. Minor delay in shipping but overall satisfied.',
    date: '1 week ago',
  ),
  const _Review(
    author: 'Chloe S.',
    avatarUrl:
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=80&q=80',
    rating: 5,
    comment:
        'This seller is legit! The watch looks even better in person. 100% recommended.',
    date: '2 weeks ago',
  ),
  const _Review(
    author: 'James K.',
    avatarUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=80&q=80',
    rating: 5,
    comment:
        'Customer service was super responsive. Got my issue resolved in 10 minutes. 👏',
    date: '3 weeks ago',
  ),
];
