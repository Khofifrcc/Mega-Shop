import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/state/cart_state.dart';
import '../../../../shared/widgets/mega_bottom_nav.dart';
import '../../data/reel_repository.dart';
import '../../domain/entities/reel.dart';

class ReelsPage extends StatefulWidget {
  const ReelsPage({super.key});

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  final _reelRepository = ReelRepository();
  List<Reel> _reels = [];
  final _likedIds = <String>{};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReels();
  }

  Future<void> _loadReels() async {
    try {
      final reels = await _reelRepository.getReels();
      setState(() {
        _reels = reels;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else if (_reels.isEmpty)
            Center(
              child: Text(
                'No reels available',
                style: AppTextStyles.sectionTitle.copyWith(color: Colors.white),
              ),
            )
          else
            PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: _reels.length,
              itemBuilder: (context, index) {
                final reel = _reels[index];

                return _ReelItem(
                  reel: reel,
                  isLiked: _likedIds.contains(reel.id),
                  onLike: () {
                    setState(() {
                      _likedIds.contains(reel.id)
                          ? _likedIds.remove(reel.id)
                          : _likedIds.add(reel.id);
                    });
                  },
                  onAddToCart: () {
                    CartStateProvider.of(context).addItem(
                      productId: reel.id,
                      name: reel.productName,
                      variant: 'Default',
                      price: reel.price,
                      imageUrl: reel.imageUrl,
                    );
                  },
                );
              },
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Reels',
                      style: AppTextStyles.sectionTitle
                          .copyWith(color: Colors.white, fontSize: 24)),
                  IconButton(
                    onPressed: () => Navigator.pushNamed(context, '/search'),
                    icon: const Icon(Icons.search_rounded, color: Colors.white),
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
          if (i == 0) Navigator.pushReplacementNamed(context, '/home');
          if (i == 2) Navigator.pushNamed(context, '/post');
          if (i == 3) Navigator.pushNamed(context, '/cart');
          if (i == 4) Navigator.pushNamed(context, '/profile');
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
        _ReelVideo(videoUrl: reel.videoUrl, fallbackImageUrl: reel.imageUrl),
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
        Positioned(
          left: 0,
          right: 0,
          bottom: 80,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage:
                                CachedNetworkImageProvider(reel.userAvatar),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              reel.username,
                              style: AppTextStyles.productName
                                  .copyWith(color: Colors.white, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _isFollowing = !_isFollowing),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: _isFollowing
                                    ? Colors.white24
                                    : AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _isFollowing ? 'Following' : 'Follow',
                                style:
                                    AppTextStyles.badge.copyWith(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
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
                              style: AppTextStyles.sectionTitle
                                  .copyWith(color: Colors.white, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            if (reel.price > 0)
                              Text(
                                '\$${reel.price.toStringAsFixed(2)}',
                                style:
                                    AppTextStyles.price.copyWith(fontSize: 20),
                              ),
                            const SizedBox(height: 10),
                            if (reel.price > 0)
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
                                  child: Text(
                                    'Add to Cart',
                                    style: AppTextStyles.buttonFilled
                                        .copyWith(fontSize: 13),
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
                Column(
                  children: [
                    _ActionButton(
                      icon: widget.isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      iconColor:
                          widget.isLiked ? AppColors.badgeSale : Colors.white,
                      label: _formatCount(
                          reel.likeCount + (widget.isLiked ? 1 : 0)),
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
                    if (reel.price > 0)
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

class _ReelVideo extends StatefulWidget {
  final String videoUrl;
  final String fallbackImageUrl;

  const _ReelVideo({
    required this.videoUrl,
    required this.fallbackImageUrl,
  });

  @override
  State<_ReelVideo> createState() => _ReelVideoState();
}

class _ReelVideoState extends State<_ReelVideo> {
  late final VideoPlayerController _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    if (widget.videoUrl.isEmpty) {
      _hasError = true;
      return;
    }

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _controller
          ..setLooping(true)
          ..play();
      }).catchError((_) {
        if (!mounted) return;
        setState(() => _hasError = true);
      });
  }

  @override
  void dispose() {
    if (!_hasError && widget.videoUrl.isNotEmpty) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || widget.videoUrl.isEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.fallbackImageUrl,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Container(color: Colors.black87),
      );
    }

    if (!_controller.value.isInitialized) {
      return Container(color: Colors.black);
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
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
            decoration: const BoxDecoration(
                color: Colors.black38, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: AppTextStyles.brandName.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}
