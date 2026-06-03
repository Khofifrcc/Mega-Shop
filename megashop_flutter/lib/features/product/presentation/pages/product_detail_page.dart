import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/state/cart_state.dart';
import '../../../home/domain/entities/product.dart';
import 'seller_profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Product Detail page — Shopee-style layout.
///
/// - Swipeable hero image gallery (PageView)
/// - Seller card with Follow button (both pointer cursor)
/// - Expandable description
/// - Fixed bottom bar (bottomNavigationBar): [🛒 Cart] [💬 Chat] [Buy Now]
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

  final List<String> _extraImages = [
    'https://images.unsplash.com/photo-1522312346375-d1a52e2b99b3?w=600&q=80',
    'https://images.unsplash.com/photo-1434056886845-dac89ffe9b56?w=600&q=80',
  ];

  // ── Navigate to seller profile ────────────────────────────────────────────

  void _openSeller(Product product) {
    final sellerAvatar = product.ownerAvatar.isNotEmpty
        ? product.ownerAvatar
        : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(product.brand)}&background=6C2BD9&color=fff';

    Navigator.pushNamed(
      context,
      '/seller',
      arguments: SellerArgs(
        id: product.ownerId.isNotEmpty
            ? product.ownerId
            : 'seller_${product.id}',
        name: product.brand,
        tagline: '🏆 Top Rated Seller · Premium Products',
        avatarUrl: sellerAvatar,
        coverUrl:
            'https://images.unsplash.com/photo-1518770660439-4636190af475?w=800&q=80',
        isVerified: true,
        productCount: 128,
        followersStr: '24.5K',
        rating: 4.9,
        products: [product],
      ),
    );
  }

  // ── Chat to seller ────────────────────────────────────────────────────────
  Future<void> _chatSeller(Product product) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first.')),
      );
      return;
    }

    if (product.ownerId == user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This is your own product.'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    try {
      final sellerId = product.ownerId;
      final ids = [user.uid, sellerId]..sort();
      final chatId = '${ids[0]}_${ids[1]}';

      final chatRef =
          FirebaseFirestore.instance.collection('chats').doc(chatId);

      final chatDoc = await chatRef.get();
      final isNewChat = !chatDoc.exists;

      final buyerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final buyerData = buyerDoc.data();

      await chatRef.set({
        'members': [user.uid, sellerId],
        'buyerId': user.uid,
        'buyerName':
            buyerData?['username'] ?? user.email?.split('@')[0] ?? 'Buyer',
        'buyerAvatar': buyerData?['profileImageUrl'] ?? '',
        'sellerId': sellerId,
        'sellerName': product.brand,
        'sellerAvatar': product.ownerAvatar,
        'lastMessage': 'Hi! I am interested in ${product.name}.',
        'unreadBy': {sellerId: isNewChat ? 1 : FieldValue.increment(1)},
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (isNewChat) {
        await chatRef.collection('messages').add({
          'senderId': user.uid,
          'type': 'product',
          'text': 'Hi! I am interested in this product. Is it still available?',
          'productId': product.id,
          'productName': product.name,
          'productPrice': product.price,
          'productImage': product.imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      Navigator.pushNamed(
        context,
        '/conversation',
        arguments: {
          'id': chatId,
          'name': product.brand,
          'avatar': product.ownerAvatar,
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chat failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = (ModalRoute.of(context)?.settings.arguments is Product)
        ? ModalRoute.of(context)!.settings.arguments as Product
        : _mockProduct;
    final isMyProduct =
        product.ownerId == FirebaseAuth.instance.currentUser?.uid;

    final images = [product.imageUrl, ..._extraImages];
    final desc = product.description.isNotEmpty
        ? product.description
        : 'No description provided.';

    return Scaffold(
      backgroundColor: AppColors.background,

      // ── FIXED bottom bar — never moves, always at bottom ─────────────────
      bottomNavigationBar: isMyProduct
          ? _OwnerBottomBar(product: product)
          : Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                  0, 8, 12, MediaQuery.of(context).padding.bottom + 8),
              child: Row(
                children: [
                  // 🛒 Cart
                  _BottomIconBtn(
                    icon: Icons.shopping_cart_outlined,
                    label: 'Cart',
                    color: AppColors.primary,
                    onTap: () {
                      CartStateProvider.of(context).addItem(
                        productId: product.id,
                        name: product.name,
                        variant: 'Default',
                        price: product.price,
                        imageUrl: product.imageUrl,
                        ownerId: product.ownerId,
                        ownerName: product.brand,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added to cart!',
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
                    },
                  ),

                  Container(width: 1, height: 36, color: AppColors.divider),

                  // 💬 Chat
                  _BottomIconBtn(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Chat',
                    color: AppColors.textPrimary,
                    onTap: () => _chatSeller(product),
                  ),

                  const SizedBox(width: 10),

                  // Buy Now (wider)
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          await CartStateProvider.of(context).addItem(
                            productId: product.id,
                            name: product.name,
                            variant: 'Default',
                            price: product.price,
                            imageUrl: product.imageUrl,
                            ownerId: product.ownerId,
                            ownerName: product.brand,
                          );

                          if (!context.mounted) return;
                          Navigator.pushNamed(context, '/checkout');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                          elevation: 0,
                          padding: EdgeInsets.zero,
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

      // ── Scrollable body ───────────────────────────────────────────────────
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero swipeable image gallery
            _HeroImageSection(
              images: images,
              currentIndex: _imageIndex,
              isFavorite: _isFavorite,
              onIndexChanged: (i) => setState(() => _imageIndex = i),
              onBack: () => Navigator.pop(context),
              onShare: () {},
              onFavorite: () => setState(() => _isFavorite = !_isFavorite),
            ),

            // Info sheet
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(product.name,
                      style: AppTextStyles.sectionTitle.copyWith(fontSize: 22)),
                  const SizedBox(height: 8),

                  // Price + free shipping
                  Row(
                    children: [
                      Text('\$${product.price.toStringAsFixed(2)}',
                          style: AppTextStyles.price.copyWith(fontSize: 22)),
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
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => _openSeller(product),
                            child: _SellerAvatar(product: product),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => _openSeller(product),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.brand,
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
                          ),
                        ),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _isFollowing = !_isFollowing),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: _isFollowing
                                    ? AppColors.primary
                                    : AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: AppColors.primary, width: 1.5),
                              ),
                              child: Text(
                                _isFollowing ? 'Following' : 'Follow',
                                style: AppTextStyles.buttonOutlined.copyWith(
                                  fontSize: 13,
                                  color: _isFollowing
                                      ? Colors.white
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  Text('Product Details',
                      style: AppTextStyles.sectionTitle.copyWith(fontSize: 17)),
                  const SizedBox(height: 8),
                  Text(
                    desc.length <= 120 || _isExpanded
                        ? desc
                        : '${desc.substring(0, 120)}...',
                    style: AppTextStyles.brandName
                        .copyWith(fontSize: 13, height: 1.6),
                  ),
                  const SizedBox(height: 6),
                  if (desc.length > 120)
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => setState(() => _isExpanded = !_isExpanded),
                        child: Text(
                          _isExpanded ? 'Show less' : 'Read more',
                          style: AppTextStyles.buttonOutlined
                              .copyWith(fontSize: 13),
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SellerAvatar extends StatelessWidget {
  final Product product;

  const _SellerAvatar({required this.product});

  @override
  Widget build(BuildContext context) {
    final avatar = product.ownerAvatar;

    if (avatar.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: CachedNetworkImageProvider(avatar),
        backgroundColor: AppColors.primarySurface,
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.primarySurface,
      child: Text(
        product.brand.isNotEmpty ? product.brand[0].toUpperCase() : 'S',
        style: AppTextStyles.productName.copyWith(
          color: AppColors.primary,
          fontSize: 18,
        ),
      ),
    );
  }
}

// ── Hero swipeable image section ──────────────────────────────────────────────

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
              width: double.infinity,
              placeholder: (_, __) =>
                  Container(color: AppColors.primarySurface),
              errorWidget: (_, __, ___) =>
                  Container(color: AppColors.primarySurface),
            ),
          ),
          // Dot indicators
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i == currentIndex ? 20 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color:
                        i == currentIndex ? AppColors.surface : Colors.white54,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          // Back / Share / Heart buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleIconBtn(icon: Icons.arrow_back_rounded, onTap: onBack),
                  Row(
                    children: [
                      _CircleIconBtn(
                          icon: Icons.share_outlined, onTap: onShare),
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

// ── Circle icon button ────────────────────────────────────────────────────────

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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.85),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }
}

// ── Bottom icon button (Cart / Chat) ─────────────────────────────────────────

class _BottomIconBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BottomIconBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withValues(alpha: 0.12),
        highlightColor: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 60,
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//edit delete
class _OwnerBottomBar extends StatelessWidget {
  final Product product;

  const _OwnerBottomBar({
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/edit-product',
                  arguments: product,
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete Product'),
                    content: const Text(
                      'Are you sure you want to delete this product?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.badgeSale,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirm != true) return;

                await FirebaseFirestore.instance
                    .collection('products')
                    .doc(product.id)
                    .delete();

                if (context.mounted) {
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product deleted successfully'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.badgeSale,
                foregroundColor: AppColors.textOnPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ── Mock product fallback ─────────────────────────────────────────────────────

final _mockProduct = Product(
  id: 'mock_detail',
  name: 'Aura Titanium Smartwatch Series X',
  brand: 'TechHaven Official',
  price: 299.00,
  imageUrl:
      'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600&q=80',
);
