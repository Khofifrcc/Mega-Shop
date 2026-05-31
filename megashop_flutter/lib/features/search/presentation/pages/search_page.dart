import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/state/cart_state.dart';
import '../../../../shared/widgets/mega_bottom_nav.dart';
import '../../../home/domain/entities/product.dart';
import '../../../home/presentation/widgets/product_card.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

/// Search page with recent search chips, interactive cursors, and a working filter sheet.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();
  final List<String> _recentSearches = [
    'Streetwear',
    'Sneakers 2024',
    'Oversized Hoodie'
  ];
//helper
  String _fullUrl(dynamic value) {
    final url = (value ?? '').toString();
    if (url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    if (url.startsWith('/')) return 'http://127.0.0.1:8000$url';
    return 'http://127.0.0.1:8000/$url';
  }

  // Filter States
  String _selectedSort = 'Latest';
  String _selectedCategory = 'All';
  String _selectedPriceRange = 'All';

  List<Product> _allProducts = [];
  bool _isLoading = true;
  Future<void> _loadProducts() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/products/'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load products');
      }

      final List data = jsonDecode(response.body);

      final products = data.map((item) {
        return Product(
          id: item['id'].toString(),
          userId: item['user_id'] ?? '',
          name: item['name'] ?? 'Product',
          brand: item['username'] ?? item['user_id'] ?? 'MegaShop',
          profilePhoto: item['profile_photo'] ?? '',
          price: (item['price'] as num).toDouble(),
          imageUrl: _fullUrl(item['image']),
          description: item['description'] ?? '',
          badge: null,
          isFavorite: false,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _allProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Filter and sort products dynamically based on search controller + filter state
  List<Product> get _filteredResults {
    final query = _searchCtrl.text.toLowerCase().trim();
    List<Product> list = _allProducts.where((p) {
      // 1. Search Query filter
      final matchesQuery = p.name.toLowerCase().contains(query) ||
          p.brand.toLowerCase().contains(query);
      if (!matchesQuery) return false;

      // 2. Category filter
      if (_selectedCategory != 'All') {
        if (_selectedCategory == 'Clothing' &&
            !p.name.toLowerCase().contains('jacket') &&
            !p.name.toLowerCase().contains('windbreaker') &&
            !p.name.toLowerCase().contains('denim')) {
          return false;
        }
        if (_selectedCategory == 'Shoes' &&
            !p.name.toLowerCase().contains('sneakers')) {
          return false;
        }
        if (_selectedCategory == 'Watches' &&
            !p.name.toLowerCase().contains('watch')) {
          return false;
        }
      }

      // 3. Price Range filter
      if (_selectedPriceRange != 'All') {
        if (_selectedPriceRange == 'Under \$100' && p.price >= 100)
          return false;
        if (_selectedPriceRange == '\$100 - \$200' &&
            (p.price < 100 || p.price > 200)) return false;
        if (_selectedPriceRange == 'Above \$200' && p.price <= 200)
          return false;
      }

      return true;
    }).toList();

    // 4. Sort results
    if (_selectedSort == 'Price: Low to High') {
      list.sort((a, b) => a.price.compareTo(b.price));
    } else if (_selectedSort == 'Price: High to Low') {
      list.sort((a, b) => b.price.compareTo(a.price));
    }

    return list;
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _FilterSheet(
          initialSort: _selectedSort,
          initialCategory: _selectedCategory,
          initialPriceRange: _selectedPriceRange,
          onApply: (sort, cat, price) {
            setState(() {
              _selectedSort = sort;
              _selectedCategory = cat;
              _selectedPriceRange = price;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _filteredResults;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leadingWidth: 40,
        leading: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.textPrimary),
            padding: EdgeInsets.zero,
          ),
        ),
        title: _SearchBar(
          controller: _searchCtrl,
          focusNode: _focusNode,
          onChanged: (_) => setState(() {}),
        ),
        actions: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: IconButton(
              onPressed: _showFilterSheet,
              icon: Icon(Icons.tune_rounded,
                  color: (_selectedSort != 'Latest' ||
                          _selectedCategory != 'All' ||
                          _selectedPriceRange != 'All')
                      ? AppColors.primary
                      : AppColors.textPrimary),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Search filters active indicators
            if (_selectedCategory != 'All' ||
                _selectedPriceRange != 'All' ||
                _selectedSort != 'Latest') ...[
              Row(
                children: [
                  Text('Filters:',
                      style: AppTextStyles.brandName
                          .copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_selectedSort != 'Latest')
                            _ActiveFilterChip(
                                label: _selectedSort,
                                onRemove: () =>
                                    setState(() => _selectedSort = 'Latest')),
                          if (_selectedCategory != 'All')
                            _ActiveFilterChip(
                                label: _selectedCategory,
                                onRemove: () =>
                                    setState(() => _selectedCategory = 'All')),
                          if (_selectedPriceRange != 'All')
                            _ActiveFilterChip(
                                label: _selectedPriceRange,
                                onRemove: () => setState(
                                    () => _selectedPriceRange = 'All')),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            Text('Search Results (${results.length})',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 18)),
            const SizedBox(height: 12),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (results.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded,
                          size: 48, color: AppColors.iconMuted.withAlpha(120)),
                      const SizedBox(height: 12),
                      Text('No products found matching filters.',
                          style: AppTextStyles.brandName),
                    ],
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.58,
                ),
                itemCount: results.length,
                itemBuilder: (context, i) {
                  final prod = results[i];
                  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                  final isMine = prod.userId == currentUserId;
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/product',
                            arguments: prod),
                        child: ProductCard(
                          product: prod,
                          onAddToCart: isMine
                              ? null
                              : () {
                                  CartStateProvider.of(context).addItem(
                                    productId: prod.id,
                                    name: prod.name,
                                    variant: 'Default',
                                    price: prod.price,
                                    imageUrl: prod.imageUrl,
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Added to cart!',
                                        style: AppTextStyles.brandName
                                            .copyWith(color: Colors.white),
                                      ),
                                      backgroundColor: AppColors.primary,
                                      behavior: SnackBarBehavior.floating,
                                      margin: const EdgeInsets.all(16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                          onBuyNow: isMine
                              ? null
                              : () {
                                  CartStateProvider.of(context).addItem(
                                    productId: prod.id,
                                    name: prod.name,
                                    variant: 'Default',
                                    price: prod.price,
                                    imageUrl: prod.imageUrl,
                                  );
                                  Navigator.pushNamed(context, '/checkout');
                                },
                        )),
                  );
                },
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
  final ValueChanged<String>? onChanged;

  const _SearchBar(
      {required this.controller, required this.focusNode, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search products...',
        hintStyle: AppTextStyles.brandName,
        prefixIcon: const Icon(Icons.search_rounded,
            color: AppColors.iconMuted, size: 20),
        suffixIcon: controller.text.isNotEmpty
            ? MouseRegion(
                cursor: SystemMouseCursors.click,
                child: IconButton(
                  onPressed: () {
                    controller.clear();
                    if (onChanged != null) onChanged!('');
                  },
                  icon: const Icon(Icons.cancel_rounded,
                      color: AppColors.iconMuted, size: 18),
                ),
              )
            : null,
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
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _RecentChip(
      {required this.label, required this.onTap, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider.withAlpha(50)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.history_rounded,
                  size: 14, color: AppColors.iconMuted),
              const SizedBox(width: 6),
              Text(label,
                  style: AppTextStyles.brandName
                      .copyWith(fontSize: 13, color: AppColors.textPrimary)),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  onRemove();
                },
                child: const Icon(Icons.close_rounded,
                    size: 14, color: AppColors.iconMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _ActiveFilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: AppTextStyles.brandName
                  .copyWith(color: AppColors.primary, fontSize: 11)),
          const SizedBox(width: 4),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.close_rounded,
                  size: 12, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter Sheet Bottom Sheet ──────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final String initialSort;
  final String initialCategory;
  final String initialPriceRange;
  final Function(String sort, String category, String priceRange) onApply;

  const _FilterSheet({
    required this.initialSort,
    required this.initialCategory,
    required this.initialPriceRange,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _sort;
  late String _category;
  late String _priceRange;

  @override
  void initState() {
    super.initState();
    _sort = widget.initialSort;
    _category = widget.initialCategory;
    _priceRange = widget.initialPriceRange;
  }

  @override
  Widget build(BuildContext context) {
    final sortOptions = ['Latest', 'Price: Low to High', 'Price: High to Low'];
    final catOptions = ['All', 'Clothing', 'Shoes', 'Watches'];
    final priceOptions = ['All', 'Under \$100', '\$100 - \$200', 'Above \$200'];

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Colors.black54, blurRadius: 16, offset: Offset(0, -4))
        ],
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
            child: Text('Sort & Filter',
                style: AppTextStyles.sectionTitle
                    .copyWith(color: Colors.white, fontSize: 18)),
          ),
          const SizedBox(height: 20),

          // Sort Section
          Text('Sort By',
              style: AppTextStyles.productName
                  .copyWith(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sortOptions.map((opt) {
              final active = _sort == opt;
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => setState(() => _sort = opt),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: active ? Colors.transparent : Colors.white24),
                    ),
                    child: Text(opt,
                        style: AppTextStyles.brandName.copyWith(
                            color: active ? Colors.white : Colors.white70,
                            fontSize: 12)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Category Section
          Text('Category',
              style: AppTextStyles.productName
                  .copyWith(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: catOptions.map((opt) {
              final active = _category == opt;
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => setState(() => _category = opt),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: active ? Colors.transparent : Colors.white24),
                    ),
                    child: Text(opt,
                        style: AppTextStyles.brandName.copyWith(
                            color: active ? Colors.white : Colors.white70,
                            fontSize: 12)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Price Section
          Text('Price Range',
              style: AppTextStyles.productName
                  .copyWith(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: priceOptions.map((opt) {
              final active = _priceRange == opt;
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => setState(() => _priceRange = opt),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: active ? Colors.transparent : Colors.white24),
                    ),
                    child: Text(opt,
                        style: AppTextStyles.brandName.copyWith(
                            color: active ? Colors.white : Colors.white70,
                            fontSize: 12)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Action buttons: Reset & Apply
          Row(
            children: [
              Expanded(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _sort = 'Latest';
                        _category = 'All';
                        _priceRange = 'All';
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white30),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Text('Reset',
                        style: AppTextStyles.buttonOutlined
                            .copyWith(color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(_sort, _category, _priceRange);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Text('Apply Filters',
                        style: AppTextStyles.buttonFilled
                            .copyWith(color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
