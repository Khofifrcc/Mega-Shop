import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/state/cart_state.dart';
import '../../../../shared/widgets/mega_bottom_nav.dart';
import '../../domain/entities/reel.dart';
import '../../data/reel_repository.dart';

/// Full-screen vertical-scroll Reels page.
///
/// Each reel fills the entire screen; swipe up/down to navigate.
/// Overlay: title + search (top), user info + product + price (bottom-left),
/// action buttons like/comment/share + cart FAB (bottom-right)

class ReelsPage extends StatefulWidget {
  const ReelsPage({super.key});

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  final _reelRepository = ReelRepository();

  // Reels data from FastAPI
  List<Reel> _reels = [];

  // Local UI state for liked reels
  final _likedIds = <String>{};

  // Loading state while API is fetching data
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReels();
  }

  // Load reels from FastAPI through ReelRepository
  Future<void> _loadReels() async {
    try {
      final reels = await _reelRepository.getReels();

      setState(() {
        _reels = reels;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Loading state
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )

          // Empty state
          else if (_reels.isEmpty)
            Center(
              child: Text(
                'No reels available',
                style: AppTextStyles.sectionTitle.copyWith(
                  color: Colors.white,
                ),
              ),
            )

          // Reels list from backend
          else
            PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: _reels.length,
              itemBuilder: (context, index) {
                final reel = _reels[index];

                return _ReelItem(
                  reel: reel,
                  isLiked: _likedIds.contains(reel.id),

                  // Like / unlike reel
                  onLike: () {
                    setState(() {
                      if (_likedIds.contains(reel.id)) {
                        _likedIds.remove(reel.id);
                      } else {
                        _likedIds.add(reel.id);
                      }
                    });
                  },

                  // Add reel product to cart
                  onAddToCart: () {
                    CartStateProvider.of(context).addItem(
                      productId: reel.id,
                      name: reel.productName,
                      variant: 'Default',
                      price: reel.price,
                      imageUrl: reel.imageUrl,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Added to cart!',
                          style: AppTextStyles.brandName.copyWith(
                            color: AppColors.textOnPrimary,
                          ),
                        ),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                );
              },
            ),

          // Fixed top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reels',
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                      shadows: const [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/search'),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: MegaBottomNav(
        currentIndex: 1,
        onTap: (i) {
          switch (i) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 2:
              Navigator.pushNamed(context, '/post');
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

class _ReelItem extends StatefulWidget {
  final Reel reel;
  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback onAddToCart;

  const _ReelItem({
    required this.reel,
    required this.isLiked,
    required this.onLike,
    required this.onAddToCart,
  });

  @override
  State<_ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<_ReelItem> {
  bool _isFollowing = false;

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        CachedNetworkImage(
          imageUrl: reel.imageUrl,
          fit: BoxFit.cover,
          placeholder: (ctx, url) => Container(color: Colors.black54),
          errorWidget: (ctx, url, err) => Container(color: Colors.black87),
        ),
        // Gradient overlay
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x80000000),
                Colors.transparent,
                Colors.transparent,
                Color(0xCC000000),
              ],
              stops: [0, 0.2, 0.6, 1],
            ),
          ),
        ),
        // (Top bar is now rendered at the ReelsPage level, not per-reel)
        // Bottom overlay
        Positioned(
          left: 0,
          right: 0,
          bottom: 80,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // ── Left: user + product info ─────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // User row
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: CachedNetworkImageProvider(
                              reel.userAvatar,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              reel.username,
                              style: AppTextStyles.productName.copyWith(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _isFollowing = !_isFollowing),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _isFollowing
                                    ? Colors.white24
                                    : AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _isFollowing ? 'Following' : 'Follow',
                                style: AppTextStyles.badge.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Product info glass card — auto-height
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              reel.productName,
                              style: AppTextStyles.sectionTitle.copyWith(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  '\$${reel.price.toStringAsFixed(2)}',
                                  style: AppTextStyles.price
                                      .copyWith(fontSize: 20),
                                ),
                                if (reel.isOnSale) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '\$${reel.originalPrice!.toStringAsFixed(2)}',
                                    style: AppTextStyles.originalPrice.copyWith(
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () =>
                                  Navigator.pushNamed(context, '/cart'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.shopping_bag_outlined,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Lihat Cart',
                                      style: AppTextStyles.buttonFilled
                                          .copyWith(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // ── Right: action buttons ────────────────────────────────
                Column(
                  children: [
                    _ActionButton(
                      icon: widget.isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      iconColor:
                          widget.isLiked ? AppColors.badgeSale : Colors.white,
                      label: _formatCount(
                        reel.likeCount + (widget.isLiked ? 1 : 0),
                      ),
                      onTap: widget.onLike,
                    ),
                    const SizedBox(height: 20),
                    _ActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: _formatCount(reel.commentCount),
                      onTap: () {},
                    ),
                    const SizedBox(height: 20),
                    _ActionButton(
                      icon: Icons.send_rounded,
                      label: 'Share',
                      onTap: () {},
                    ),
                    const SizedBox(height: 20),
                    // Cart FAB (amber)
                    GestureDetector(
                      onTap: widget.onAddToCart,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shopping_cart_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    this.iconColor = Colors.white,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black38,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.brandName.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ── Mock data ─────────────────────────────────────────────────────────────────
