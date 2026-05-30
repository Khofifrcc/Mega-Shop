import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/state/cart_state.dart';
import '../../../../shared/widgets/mega_bottom_nav.dart';
import '../../domain/entities/product.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/stories_row.dart';
import '../widgets/trending_grid.dart';
import '../../../product/data/product_repository.dart';
import '../../../post/data/post_repository.dart';
import '../../../../shared/models/post_model.dart';

/// Main Home screen of MegaShop.
///
/// Orchestrates data loading (via [HomeLocalDataSource]) and delegates
/// rendering to purpose-built child widgets.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _productRepository = ProductRepository();
  final _postRepository = PostRepository();

  int _navIndex = 0;

  List<Product> _products = [];
  List<PostModel> _posts = [];
  bool _isLoading = true;
  late final List _stories;
  late final List<String> _categories;

  @override
  void initState() {
    super.initState();
    _stories = [];
    _categories = ['All', 'Fashion', 'Tech'];

    _loadProducts();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      final posts = await _postRepository.getPosts();

      setState(() {
        _posts = posts;
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _productRepository.getProducts();

      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

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
    CartStateProvider.of(context).addItem(
      productId: product.id,
      name: product.name,
      variant: 'Default',
      price: product.price,
      imageUrl: product.imageUrl,
    );
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
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                CategoryFilterBar(
                  categories: _categories,
                  onCategoryChanged: (_) {},
                ),
                const SizedBox(height: 20),
                StoriesRow(stories: _stories.cast()),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child:
                      Text('Trending Now', style: AppTextStyles.sectionTitle),
                ),
                const SizedBox(height: 14),
                _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : TrendingGrid(
                        products: _products,
                        onAddToCart: _handleAddToCart,
                        onBuyNow: _handleBuyNow,
                        onFavoriteToggle: (product, isFav) {},
                        onProductTap: (product) => Navigator.pushNamed(
                          context,
                          '/product',
                          arguments: product,
                        ),
                      ),
                const SizedBox(height: 24),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Latest Posts',
                    style: AppTextStyles.sectionTitle,
                  ),
                ),
                const SizedBox(height: 14),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];

                    return Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(18),
                            ),
                            child: Image.network(
                              post.image,
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
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
                  },
                ),
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
}
