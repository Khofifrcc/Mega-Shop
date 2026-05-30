import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/state/cart_state.dart';
import '../../../../shared/widgets/mega_bottom_nav.dart';
import '../../domain/entities/product.dart';
import '../widgets/app_bar_widget.dart';
import '../../../product/data/product_repository.dart';
import '../../../post/data/post_repository.dart';
import '../../../../shared/models/post_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _productRepository = ProductRepository();
  final _postRepository = PostRepository();

  int _navIndex = 0;
  bool _isLoading = true;

  List<Product> _products = [];
  List<PostModel> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    try {
      final products = await _productRepository.getProducts();
      final posts = await _postRepository.getPosts();

      setState(() {
        _products = products;
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint(e.toString());
    }
  }

  void _handleAddToCart(Product product) {
    CartStateProvider.of(context).addItem(
      productId: product.id,
      name: product.name,
      variant: 'Default',
      price: product.price,
      imageUrl: product.imageUrl,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${product.name} added to cart!',
          style:
              AppTextStyles.brandName.copyWith(color: AppColors.textOnPrimary),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleBuyNow(Product product) {
    _handleAddToCart(product);
    Navigator.pushNamed(context, '/checkout');
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartStateProvider.of(context);

    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: MegaShopAppBar(
            cartItemCount: cart.itemCount,
            onSearchTap: () => Navigator.pushNamed(context, '/search'),
            onCartTap: () => Navigator.pushNamed(context, '/cart'),
            onChatTap: () => Navigator.pushNamed(context, '/chat'),
          ),
          body: RefreshIndicator(
            onRefresh: _loadFeed,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      ..._products.map(_buildProductFeedCard),
                      ..._posts.map(_buildPostFeedCard),
                    ],
                  ),
          ),
          bottomNavigationBar: MegaBottomNav(
            currentIndex: _navIndex,
            onTap: (i) {
              if (i == _navIndex) return;
              setState(() => _navIndex = i);

              switch (i) {
                case 1:
                  Navigator.pushNamed(context, '/reels');
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
      },
    );
  }

  Widget _buildProductFeedCard(Product product) {
    final user = FirebaseAuth.instance.currentUser;
    final currentUserName = user?.email?.split('@').first ?? 'User';
    final isOwnProduct = product.brand == currentUserName;
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.pushNamed(
          context,
          '/product',
          arguments: product,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFeedHeader(
              name: product.brand,
              subtitle: 'Product post',
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                product.imageUrl,
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 300,
                  color: AppColors.primarySurface,
                  child: const Center(
                    child: Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: AppTextStyles.productName),
                  const SizedBox(height: 6),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: AppTextStyles.price.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 12),
                  if (isOwnProduct)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Your Product',
                          style: AppTextStyles.buttonOutlined,
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _handleAddToCart(product),
                            child: Text(
                              'Add to Cart',
                              style: AppTextStyles.buttonOutlined,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _handleBuyNow(product),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              elevation: 0,
                            ),
                            child: Text(
                              'Buy Now',
                              style: AppTextStyles.buttonFilled,
                            ),
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

  Widget _buildPostFeedCard(PostModel post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeedHeader(
            name: post.userId,
            subtitle: 'Regular post',
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              post.image,
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 300,
                color: AppColors.primarySurface,
                child: const Center(
                  child: Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              post.caption,
              style: AppTextStyles.productName,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedHeader({
    required String name,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primarySurface,
            child: Icon(Icons.person, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.productName),
                Text(
                  subtitle,
                  style: AppTextStyles.brandName.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.more_horiz, color: AppColors.iconMuted),
        ],
      ),
    );
  }
}
