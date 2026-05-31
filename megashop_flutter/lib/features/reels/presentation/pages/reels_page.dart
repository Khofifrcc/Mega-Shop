import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/state/cart_state.dart';
import '../../../../shared/state/chat_state.dart';
import '../../../../shared/widgets/mega_bottom_nav.dart';
import '../../domain/entities/reel.dart';
import '../../../home/domain/entities/product.dart';
import '../../../product/presentation/pages/seller_profile_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

/// Full-screen vertical Reels — Instagram-style.
///
/// Features:
/// - Real video playback (video_player) with auto-play on visible reel
/// - Sticky header top bar (Reels + Search) that stays stationary when swiping
/// - Reordered overlay details: Product glass card on top, user info in middle, caption below
/// - Tap product glass card to navigate to Product Detail Page (/product)
/// - Add to Cart (circular icon logo only) and Buy Now (pill button) inside card
/// - Like / Live comment system / Share action buttons
/// - Pointer cursor on hover for every button
class ReelsPage extends StatefulWidget {
  const ReelsPage({super.key});

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  List<Reel> _reels = [];
  bool _isLoadingReels = true;
  final _likedIds = <String>{};
  int _currentIndex = 0;

  // Track comments per reel ID so they persist during the session and update the count
  final Map<String, List<_Comment>> _reelComments = {};

  @override
  void initState() {
    super.initState();

    _loadReels();
    // Initialize mock comments for each reel
    for (var reel in _reels) {
      _reelComments[reel.id] = [
        const _Comment(
            author: 'diana_v',
            avatar:
                'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=80&q=80',
            text: '🔥 This looks amazing! Ordering right now',
            time: '2m'),
        const _Comment(
            author: 'marcus_t',
            avatar:
                'https://images.unsplash.com/photo-1527980965255-d3b416303d12?w=80&q=80',
            text: 'Love the quality! Already bought 2 of these 😍',
            time: '5m'),
        const _Comment(
            author: 'chloe_s',
            avatar:
                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=80&q=80',
            text: 'How is the sizing? Running true to size?',
            time: '8m'),
      ];
    }
  }

  String _fullUrl(dynamic value) {
    final url = (value ?? '').toString();

    if (url.isEmpty || url == 'string') return '';
    if (url.startsWith('http')) return url;
    if (url.startsWith('/')) return 'http://127.0.0.1:8000$url';

    return 'http://127.0.0.1:8000/$url';
  }

  Future<void> _loadReels() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/reels/'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load reels');
      }

      final List data = jsonDecode(response.body);

      final reels = data
          .map((item) {
            final videoUrl = _fullUrl(item['video']);

            // Skip broken dummy/test data like "video": "string"
            if (videoUrl.isEmpty) return null;

            final isProduct = item['is_product'] == 1 ||
                item['is_product'] == true ||
                item['is_product'] == '1' ||
                item['is_product'] == 'true' ||
                ((item['product_name'] ?? '').toString().isNotEmpty &&
                    ((item['price'] as num?)?.toDouble() ?? 0) > 0);

            final productImageUrl = _fullUrl(item['image']);

            return Reel(
              id: item['id'].toString(),
              userId: item['user_id'] ?? '',
              username: item['username'] ?? item['user_id'] ?? '@user',
              userAvatar: _fullUrl(item['profile_photo']).isNotEmpty
                  ? _fullUrl(item['profile_photo'])
                  : 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&q=80',
              caption: item['caption'] ?? '',
              productName: isProduct ? (item['product_name'] ?? 'Product') : '',
              price: isProduct ? ((item['price'] as num?)?.toDouble() ?? 0) : 0,
              imageUrl: isProduct && productImageUrl.isNotEmpty
                  ? productImageUrl
                  : 'https://picsum.photos/500',
              videoUrl: videoUrl,
              likeCount: 0,
              commentCount: 0,
            );
          })
          .whereType<Reel>()
          .toList();

      if (mounted) {
        setState(() {
          _reels = reels;
          _isLoadingReels = false;

          for (var reel in _reels) {
            _reelComments[reel.id] = [];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _reels = [];
          _isLoadingReels = false;
        });
      }
    }
  }

  void _handlePageChange(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // Hide status bar for immersive full-screen experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (_isLoadingReels) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Swipeable reels feed
          PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: _reels.length,
            onPageChanged: _handlePageChange,
            itemBuilder: (context, index) {
              final reel = _reels[index];
              final currentCommentCount =
                  _reelComments[reel.id]?.length ?? reel.commentCount;
              return _ReelItem(
                reel: reel,
                isActive: index == _currentIndex,
                isLiked: _likedIds.contains(reel.id),
                commentCount: currentCommentCount,
                onLike: () => setState(() {
                  if (_likedIds.contains(reel.id)) {
                    _likedIds.remove(reel.id);
                  } else {
                    _likedIds.add(reel.id);
                  }
                }),
                onComment: () => _showComments(context, reel),
                onShare: () => _showShare(context, reel),
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
                      content: Text('Added to cart!',
                          style: AppTextStyles.brandName
                              .copyWith(color: Colors.white)),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),

          // Sticky static top header bar (Reels + Search)
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
                            offset: Offset(0, 2))
                      ],
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
                            overlays: SystemUiOverlay.values);
                        _showReelsSearch(context);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: const Icon(Icons.search_rounded,
                            color: Colors.white, size: 22),
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
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
              overlays: SystemUiOverlay.values);
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

  // ── Comment bottom sheet ────────────────────────────────────────────────────
  void _showReelsSearch(BuildContext context) {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = controller.text.toLowerCase().trim();

            final results = query.isEmpty
                ? <Reel>[]
                : _reels.where((reel) {
                    return reel.caption.toLowerCase().contains(query) ||
                        reel.username.toLowerCase().contains(query) ||
                        reel.productName.toLowerCase().contains(query);
                  }).toList();

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.92,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: controller,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        onChanged: (_) => setModalState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search reels...',
                          hintStyle: const TextStyle(color: Colors.white54),
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: results.isEmpty
                            ? Center(
                                child: Text(
                                  query.isEmpty
                                      ? 'Type to search reels'
                                      : 'No reels found',
                                  style: const TextStyle(color: Colors.white54),
                                ),
                              )
                            : GridView.builder(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.62,
                                ),
                                itemCount: results.length,
                                itemBuilder: (_, i) {
                                  final reel = results[i];

                                  return GestureDetector(
                                    onTap: () {
                                      final index = _reels.indexWhere(
                                        (r) => r.id == reel.id,
                                      );

                                      if (index != -1) {
                                        Navigator.pop(context);
                                        setState(() => _currentIndex = index);
                                      }
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Container(
                                            color: Colors.black87,
                                            child: const Center(
                                              child: Icon(
                                                Icons.play_circle_fill_rounded,
                                                color: Colors.white,
                                                size: 52,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            left: 8,
                                            right: 8,
                                            bottom: 8,
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    reel.productName.isNotEmpty
                                                        ? reel.productName
                                                        : reel.caption,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    '@${reel.username} · \$${reel.price.toStringAsFixed(2)}',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showComments(BuildContext context, Reel reel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(
        reel: reel,
        comments: _reelComments[reel.id] ?? [],
        onCommentAdded: (text) {
          setState(() {
            _reelComments[reel.id] = [
              _Comment(
                author: 'you',
                avatar:
                    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=80&q=80',
                text: text,
                time: 'now',
              ),
              ...(_reelComments[reel.id] ?? []),
            ];
          });
        },
      ),
    );
  }

  // ── Share bottom sheet ──────────────────────────────────────────────────────

  void _showShare(BuildContext context, Reel reel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShareSheet(reel: reel),
    );
  }
}

// ── Single Reel Item ──────────────────────────────────────────────────────────

class _ReelItem extends StatefulWidget {
  final Reel reel;
  final bool isActive;
  final bool isLiked;
  final int commentCount;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onAddToCart;

  const _ReelItem({
    required this.reel,
    required this.isActive,
    required this.isLiked,
    required this.commentCount,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onAddToCart,
  });

  @override
  State<_ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<_ReelItem>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _isPaused = false;
  bool _isFollowing = false;

  // Double-tap heart animation
  late AnimationController _heartAnim;
  bool _showHeart = false;

  @override
  void initState() {
    super.initState();
    _heartAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          setState(() => _showHeart = false);
          _heartAnim.reset();
        }
      });

    _controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.reel.videoUrl))
          ..initialize().then((_) {
            if (mounted) {
              setState(() => _initialized = true);
              if (widget.isActive) _controller.play();
              _controller.setLooping(true);
            }
          });
  }

  @override
  void didUpdateWidget(_ReelItem old) {
    super.didUpdateWidget(old);
    if (widget.isActive != old.isActive) {
      if (widget.isActive) {
        _controller.play();
        setState(() => _isPaused = false);
      } else {
        _controller.pause();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _heartAnim.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _isPaused = !_isPaused;
      _isPaused ? _controller.pause() : _controller.play();
    });
  }

  void _doubleTapLike() {
    if (!widget.isLiked) widget.onLike();
    setState(() => _showHeart = true);
    _heartAnim.forward();
  }

  void _goToDetail() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    Navigator.pushNamed(
      context,
      '/product',
      arguments: Product(
        id: widget.reel.id,
        userId: widget.reel.userId,
        name: widget.reel.productName,
        brand: widget.reel.username,
        price: widget.reel.price,
        originalPrice: widget.reel.originalPrice,
        imageUrl: widget.reel.imageUrl,
      ),
    );
  }

  void _goToSellerProfile() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    Navigator.pushNamed(
      context,
      '/seller',
      arguments: SellerArgs(
        id: 'seller_${widget.reel.id}',
        name: widget.reel.username,
        tagline: '🏆 Top Rated Seller · Premium Products',
        avatarUrl: widget.reel.userAvatar,
        coverUrl:
            'https://images.unsplash.com/photo-1518770660439-4636190af475?w=800&q=80',
        isVerified: true,
        productCount: 45,
        followersStr: '12.4K',
        rating: 4.8,
        products: [
          Product(
            id: widget.reel.id,
            userId: widget.reel.userId,
            name: widget.reel.productName,
            brand: widget.reel.username,
            price: widget.reel.price,
            originalPrice: widget.reel.originalPrice,
            imageUrl: widget.reel.imageUrl,
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMyReel =
        widget.reel.userId == FirebaseAuth.instance.currentUser?.uid;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Background: Pure video experience with circular loader ──────
        GestureDetector(
          onTap: _togglePlay,
          onDoubleTap: _doubleTapLike,
          child: Container(
            color: Colors.black,
            child: _initialized
                ? SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ),

        // ── Dark gradient overlay ───────────────────────────────────────
        IgnorePointer(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x99000000),
                  Colors.transparent,
                  Colors.transparent,
                  Color(0xDD000000),
                ],
                stops: [0, 0.15, 0.55, 1],
              ),
            ),
          ),
        ),

        // ── Pause indicator ─────────────────────────────────────────────
        if (_isPaused)
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 40),
            ),
          ),

        // ── Double-tap heart animation ─────────────────────────────────
        if (_showHeart)
          Center(
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: _heartAnim,
                curve: Curves.elasticOut,
              ),
              child: const Icon(Icons.favorite_rounded,
                  color: Colors.redAccent, size: 100),
            ),
          ),

        // ── Bottom overlay ─────────────────────────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 80,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // ── Left: card details + user info + caption ────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Product glass card (top of overlays)
                      if (widget.reel.productName.isNotEmpty &&
                          widget.reel.price > 0)
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: _goToDetail,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Row(
                                children: [
                                  // Product thumbnail
                                  Container(
                                    width: 48,
                                    height: 48,
                                    color: Colors.black,
                                    child: const Icon(
                                      Icons.play_circle_fill_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.reel.productName,
                                          style: AppTextStyles.productName
                                              .copyWith(
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              '\$${widget.reel.price.toStringAsFixed(2)}',
                                              style: AppTextStyles.price
                                                  .copyWith(fontSize: 14),
                                            ),
                                            if (widget.reel.isOnSale) ...[
                                              const SizedBox(width: 6),
                                              Text(
                                                '\$${widget.reel.originalPrice!.toStringAsFixed(2)}',
                                                style: AppTextStyles
                                                    .originalPrice
                                                    .copyWith(
                                                  color: Colors.white54,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Buttons area
                                  // Buttons area
                                  if (!isMyReel)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Add to Cart: logo only, no text
                                        MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: GestureDetector(
                                            onTap: widget.onAddToCart,
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white24,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                    color: Colors.white30),
                                              ),
                                              child: const Icon(
                                                Icons.add_shopping_cart_rounded,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        // Buy Now: pill button with text
                                        MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: GestureDetector(
                                            onTap: () {
                                              CartStateProvider.of(context)
                                                  .addItem(
                                                productId: widget.reel.id,
                                                name: widget.reel.productName,
                                                variant: 'Default',
                                                price: widget.reel.price,
                                                imageUrl: widget.reel.imageUrl,
                                              );
                                              SystemChrome
                                                  .setEnabledSystemUIMode(
                                                      SystemUiMode.manual,
                                                      overlays: SystemUiOverlay
                                                          .values);
                                              Navigator.pushNamed(
                                                  context, '/checkout');
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 8),
                                              decoration: BoxDecoration(
                                                color: AppColors.accent,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Text(
                                                'Buy Now',
                                                style: AppTextStyles
                                                    .buttonFilled
                                                    .copyWith(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),

                      // 2. User row (middle of overlays)
                      Row(
                        children: [
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: _goToSellerProfile,
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: widget.reel.userAvatar,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) =>
                                      Container(color: Colors.white24),
                                  errorWidget: (_, __, ___) =>
                                      Container(color: Colors.white24),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: _goToSellerProfile,
                                child: Text(
                                  widget.reel.username,
                                  style: AppTextStyles.productName.copyWith(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                if (isMyReel) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text("This is your own reel")),
                                  );
                                  return;
                                }

                                setState(() => _isFollowing = !_isFollowing);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _isFollowing
                                      ? Colors.white24
                                      : AppColors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.white38, width: 1),
                                ),
                                child: Text(
                                  isMyReel
                                      ? 'Your Reel'
                                      : (_isFollowing ? 'Following' : 'Follow'),
                                  style: AppTextStyles.badge
                                      .copyWith(fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // 3. Caption / description (bottom of overlays)
                      Text(
                        widget.reel.caption,
                        style: AppTextStyles.brandName.copyWith(
                            color: Colors.white70, fontSize: 13, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // ── Right: action buttons ──────────────────────────────
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Like
                    _ActionBtn(
                      icon: widget.isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      iconColor:
                          widget.isLiked ? Colors.redAccent : Colors.white,
                      label: _fmt(
                          widget.reel.likeCount + (widget.isLiked ? 1 : 0)),
                      onTap: widget.onLike,
                    ),
                    const SizedBox(height: 18),

                    // Comment
                    _ActionBtn(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: _fmt(widget.commentCount),
                      onTap: widget.onComment,
                    ),
                    const SizedBox(height: 18),

                    // Share
                    _ActionBtn(
                      icon: Icons.send_rounded,
                      label: 'Share',
                      onTap: widget.onShare,
                    ),
                    const SizedBox(height: 18),

                    // Video progress ring (mini)
                    if (_initialized) _VideoProgress(controller: _controller),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';
}

// ── Action button (Like / Comment / Share) ────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    this.iconColor = Colors.white,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.brandName
                  .copyWith(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tiny circular video progress indicator ────────────────────────────────────

class _VideoProgress extends StatefulWidget {
  final VideoPlayerController controller;
  const _VideoProgress({required this.controller});

  @override
  State<_VideoProgress> createState() => _VideoProgressState();
}

class _VideoProgressState extends State<_VideoProgress> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTick);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTick);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dur = widget.controller.value.duration.inMilliseconds;
    final pos = widget.controller.value.position.inMilliseconds;
    final progress = dur > 0 ? (pos / dur).clamp(0.0, 1.0) : 0.0;
    return SizedBox(
      width: 32,
      height: 32,
      child: CircularProgressIndicator(
        value: progress,
        strokeWidth: 2.5,
        color: AppColors.primary,
        backgroundColor: Colors.white24,
      ),
    );
  }
}

// ── Comments bottom sheet ─────────────────────────────────────────────────────

class _CommentsSheet extends StatefulWidget {
  final Reel reel;
  final List<_Comment> comments;
  final ValueChanged<String> onCommentAdded;

  const _CommentsSheet({
    required this.reel,
    required this.comments,
    required this.onCommentAdded,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${widget.comments.length} Comments',
              style: AppTextStyles.sectionTitle
                  .copyWith(color: Colors.white, fontSize: 16),
            ),
            const Divider(color: Colors.white12, height: 20),

            // Comment list
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.comments.length,
                itemBuilder: (_, i) => _CommentTile(c: widget.comments[i]),
              ),
            ),

            // Input
            Container(
              padding: EdgeInsets.fromLTRB(
                  16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              color: const Color(0xFF1A1A1A),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(
                        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=80&q=80'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Add a comment…',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white10,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        if (_ctrl.text.trim().isEmpty) return;
                        widget.onCommentAdded(_ctrl.text.trim());
                        _ctrl.clear();
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
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

class _CommentTile extends StatelessWidget {
  final _Comment c;
  const _CommentTile({required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 18, backgroundImage: NetworkImage(c.avatar)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('@${c.author}',
                        style: AppTextStyles.productName
                            .copyWith(color: Colors.white, fontSize: 13)),
                    const SizedBox(width: 8),
                    Text(c.time,
                        style: AppTextStyles.brandName
                            .copyWith(color: Colors.white38, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(c.text,
                    style: AppTextStyles.brandName
                        .copyWith(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {},
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.favorite_border_rounded,
                    color: Colors.white38, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Share bottom sheet ────────────────────────────────────────────────────────

class _ShareSheet extends StatefulWidget {
  final Reel reel;
  const _ShareSheet({required this.reel});

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final Set<String> _sentFriendIds = {};

  @override
  Widget build(BuildContext context) {
    final friends = ChatService.instance.friends;
    final options = [
      (Icons.link_rounded, 'Copy Link'),
      (Icons.bookmark_border_rounded, 'Save Reel'),
      (Icons.report_outlined, 'Report'),
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('Share',
                style: AppTextStyles.sectionTitle
                    .copyWith(color: Colors.white, fontSize: 18)),
          ),
          const SizedBox(height: 20),

          // Send to Friends horizontal list
          Text(
            'Send to Friends',
            style: AppTextStyles.productName
                .copyWith(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: friends.length,
              itemBuilder: (context, idx) {
                final f = friends[idx];
                final isSent = _sentFriendIds.contains(f.id);
                return Container(
                  width: 85,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage:
                            CachedNetworkImageProvider(f.avatarUrl),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        f.name.split(' ').first,
                        style: AppTextStyles.brandName
                            .copyWith(color: Colors.white70, fontSize: 11),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: isSent
                              ? null
                              : () {
                                  setState(() {
                                    _sentFriendIds.add(f.id);
                                  });
                                  ChatService.instance.sendReel(
                                    conversationId: f.id,
                                    reelId: widget.reel.id,
                                    productName: widget.reel.productName,
                                    productPrice: widget.reel.price,
                                    productImage: widget.reel.imageUrl,
                                    videoUrl: widget.reel.videoUrl,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Sent to ${f.name}!',
                                          style: AppTextStyles.brandName
                                              .copyWith(color: Colors.white)),
                                      backgroundColor: AppColors.primary,
                                      behavior: SnackBarBehavior.floating,
                                      margin: const EdgeInsets.all(16),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  isSent ? Colors.white10 : AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                              border: isSent
                                  ? Border.all(color: Colors.white24)
                                  : null,
                            ),
                            child: Text(
                              isSent ? 'Sent' : 'Send',
                              style: AppTextStyles.badge.copyWith(
                                fontSize: 10,
                                color: isSent ? Colors.white38 : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(color: Colors.white12, height: 20),

          // Core sharing options
          ...options.map((opt) => MouseRegion(
                cursor: SystemMouseCursors.click,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: Colors.white12,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(opt.$1, color: Colors.white, size: 22),
                  ),
                  title: Text(opt.$2,
                      style: AppTextStyles.productName
                          .copyWith(color: Colors.white, fontSize: 15)),
                  onTap: () {
                    if (opt.$2 == 'Copy Link') {
                      Clipboard.setData(
                          ClipboardData(text: widget.reel.videoUrl));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Link copied to clipboard!',
                              style: AppTextStyles.brandName
                                  .copyWith(color: Colors.white)),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else if (opt.$2 == 'Save Reel') {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Reel saved to bookmarks!',
                              style: AppTextStyles.brandName
                                  .copyWith(color: Colors.white)),
                          backgroundColor: AppColors.accent,
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else if (opt.$2 == 'Report') {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Thank you for reporting. We will review this Reel.',
                              style: AppTextStyles.brandName
                                  .copyWith(color: Colors.white)),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
              )),
        ],
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

class _Comment {
  final String author;
  final String avatar;
  final String text;
  final String time;

  const _Comment({
    required this.author,
    required this.avatar,
    required this.text,
    required this.time,
  });
}
