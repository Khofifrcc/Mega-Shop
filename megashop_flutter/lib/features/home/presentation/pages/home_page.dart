import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/state/cart_state.dart';
import '../../../../shared/widgets/mega_bottom_nav.dart';
import '../../data/datasources/home_local_data_source.dart';
import '../../data/mappers/product_mapper.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/story.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/stories_row.dart';
import '../widgets/story_viewer.dart';
import '../widgets/trending_grid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

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
  final _dataSource = HomeLocalDataSource();

  int _navIndex = 0;

  late final List<Product> _products;
  late final List<String> _categories;

  // ── Address state ─────────────────────────────────────────────────────────
  final List<_Address> _addresses = [];
  int _selectedAddressIndex = 0;

  // ── Story state ───────────────────────────────────────────────────────────
  final Set<String> _viewedStoryIds = {};
  String _selectedCategory = 'All';
//category

  @override
  void initState() {
    super.initState();
    _products = _dataSource.getTrendingProducts();

    _categories = _dataSource.getCategories();
    _loadAddresses();
  }

  Future<void> _handleAddToCart(Product product) async {
    await CartStateProvider.of(context).addItem(
      productId: product.id,
      name: product.name,
      variant: 'Default',
      price: product.price,
      imageUrl: product.imageUrl,
      ownerId: product.ownerId,
      ownerName: product.brand,
    );
    if (!mounted) return;
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

  Future<void> _loadAddresses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .get();

    setState(() {
      _addresses.clear();
      _addresses.addAll(snapshot.docs.map((doc) {
        final data = doc.data();
        return _Address(
          id: doc.id,
          label: data['label'] ?? '',
          detail: data['detail'] ?? '',
        );
      }));

      if (_selectedAddressIndex >= _addresses.length) {
        _selectedAddressIndex = 0;
      }
    });
  }

  Future<void> _handleBuyNow(Product product) async {
    await CartStateProvider.of(context).addItem(
      productId: product.id,
      name: product.name,
      variant: 'Default',
      price: product.price,
      imageUrl: product.imageUrl,
      ownerId: product.ownerId,
      ownerName: product.brand,
    );

    if (!mounted) return;
    Navigator.pushNamed(context, '/checkout');
  }

  // ── Story viewer ──────────────────────────────────────────────────────────

  Future<void> _openOwnStory() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('Add to Your Story',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 18)),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: AppColors.primary),
              ),
              title: const Text('Take a Photo'),
              onTap: () async {
                Navigator.pop(context);
                final file = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 85,
                );

                if (file == null) return;

                final bytes = await file.readAsBytes();

                await _uploadStoryToFirebase(bytes);
              },
            ),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_rounded,
                    color: AppColors.primary),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final file = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                );

                if (file == null) return;

                final bytes = await file.readAsBytes();

                await _uploadStoryToFirebase(bytes);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  //upload to firebase
  Future<void> _uploadStoryToFirebase(Uint8List bytes) async {
    debugPrint('STORY UPLOAD START');

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('stories')
          .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      debugPrint('STORY STORAGE UPLOAD...');

      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final imageUrl = await ref.getDownloadURL();

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data();

      final username = userData?['username'] ?? user.email ?? 'User';
      final profileImageUrl = userData?['profileImageUrl'] ?? '';

      await FirebaseFirestore.instance.collection('stories').add({
        'ownerId': user.uid,
        'username': username,
        'userAvatar': profileImageUrl,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('STORY FIRESTORE SAVED');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Story uploaded successfully!'),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      debugPrint('STORY ERROR: $e');
    }
  }

  // ── Address bottom sheet ──────────────────────────────────────────────────

  void _openAddressSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _AddressBottomSheet(
        addresses: _addresses,
        selectedIndex: _selectedAddressIndex,
        onSelect: (i) {
          setState(() => _selectedAddressIndex = i);
          Navigator.pop(sheetContext);
        },
        onAdd: (address) async {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return;

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('addresses')
              .add({
            'label': address.label,
            'detail': address.detail,
            'createdAt': FieldValue.serverTimestamp(),
          });

          if (!sheetContext.mounted) return;
          Navigator.pop(sheetContext);
        },
        onDelete: (i) async {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return;

          final addressId = _addresses[i].id;

          if (addressId != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('addresses')
                .doc(addressId)
                .delete();
          }

          await _loadAddresses();
        },
      ),
    );
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
            onSearchTap: () => Navigator.pushNamed(context, '/search'),
            onChatTap: () => Navigator.pushNamed(context, '/chat'),
            onNotificationTap: () =>
                Navigator.pushNamed(context, '/notifications'),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Current address bar ──────────────────────────────────
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _openAddressSheet,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _addresses.isEmpty
                                  ? 'Add delivery address'
                                  : '${_addresses[_selectedAddressIndex].label} · ${_addresses[_selectedAddressIndex].detail}',
                              style: AppTextStyles.brandName
                                  .copyWith(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded,
                              size: 16, color: AppColors.iconMuted),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                CategoryFilterBar(
                  categories: _categories,
                  onCategoryChanged: (category) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                ),
                const SizedBox(height: 20),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('stories')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final firebaseStories = snapshot.data?.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;

                          return Story(
                            id: doc.id,
                            username: data['username'] ?? 'User',
                            imageUrl: data['imageUrl'],
                            ownerId: data['ownerId'] ?? '',
                          );
                        }).toList() ??
                        [];

                    final currentUserId =
                        FirebaseAuth.instance.currentUser?.uid;

                    // Sort so user's own uploaded stories are on the far left, right after the "Your Story" add button
                    final ownStories = firebaseStories
                        .where((s) => s.ownerId == currentUserId)
                        .toList();
                    final otherStories = firebaseStories
                        .where((s) => s.ownerId != currentUserId)
                        .toList();

                    final viewableStories = [...ownStories, ...otherStories];

                    final storiesToShow = [
                      const Story(
                        id: 'own_story',
                        username: 'Your Story',
                        isOwnStory: true,
                      ),
                      ...viewableStories,
                    ];

                    return StoriesRow(
                      stories: storiesToShow,
                      viewedStoryIds: _viewedStoryIds,
                      ownStoryImagePath: null,
                      onStoryTap: (index) {
                        if (index == 0) return;

                        final realIndex = index - 1;

                        Navigator.of(context).push(
                          PageRouteBuilder(
                            opaque: false,
                            barrierColor: Colors.black87,
                            pageBuilder: (_, __, ___) => StoryViewer(
                              stories: viewableStories,
                              initialIndex: realIndex,
                            ),
                            transitionsBuilder: (_, animation, __, child) =>
                                FadeTransition(
                                    opacity: animation, child: child),
                          ),
                        );
                      },
                      onOwnStoryTap: _openOwnStory,
                    );
                  },
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child:
                      Text('Trending Now', style: AppTextStyles.sectionTitle),
                ),
                const SizedBox(height: 14),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('products')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return TrendingGrid(
                        products: _products,
                        onAddToCart: _handleAddToCart,
                        onBuyNow: _handleBuyNow,
                        onFavoriteToggle: (product, isFav) {},
                        onProductTap: (product) => Navigator.pushNamed(
                            context, '/product',
                            arguments: product),
                      );
                    }

                    final firebaseProducts =
                        snapshot.data!.docs.map(productFromFirestore).toList();
                    final filteredProducts = _selectedCategory == 'All'
                        ? firebaseProducts
                        : firebaseProducts.where((product) {
                            final brand = product.brand.toLowerCase();

                            switch (_selectedCategory) {
                              case 'Fashion':
                                return true; // sementara semua masuk fashion
                              case 'Tech':
                                return brand.contains('tech');
                              case 'Home':
                                return brand.contains('home');
                              case 'Beauty':
                                return brand.contains('beauty');
                              default:
                                return true;
                            }
                          }).toList();
                    return TrendingGrid(
                      products: filteredProducts,
                      onAddToCart: _handleAddToCart,
                      onBuyNow: _handleBuyNow,
                      onFavoriteToggle: (product, isFav) {},
                      onProductTap: (product) => Navigator.pushNamed(
                          context, '/product',
                          arguments: product),
                    );
                  },
                ),
                const SizedBox(height: 24),
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

// ── Address model ─────────────────────────────────────────────────────────────

class _Address {
  String? id;
  String label;
  String detail;

  _Address({
    this.id,
    required this.label,
    required this.detail,
  });
}

// ── Address bottom sheet ──────────────────────────────────────────────────────

class _AddressBottomSheet extends StatefulWidget {
  final List<_Address> addresses;
  final int selectedIndex;
  final void Function(int) onSelect;
  final Future<void> Function(_Address) onAdd;
  final void Function(int) onDelete;

  const _AddressBottomSheet({
    required this.addresses,
    required this.selectedIndex,
    required this.onSelect,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  State<_AddressBottomSheet> createState() => _AddressBottomSheetState();
}

class _AddressBottomSheetState extends State<_AddressBottomSheet> {
  bool _showAddForm = false;
  final _labelCtrl = TextEditingController();
  final _detailCtrl = TextEditingController();

  @override
  void dispose() {
    _labelCtrl.dispose();
    _detailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 16,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text('Delivery Address',
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 18)),
            ],
          ),
          const SizedBox(height: 16),

          // ── Saved addresses ───────────────────────────────────────────
          ...List.generate(widget.addresses.length, (i) {
            final addr = widget.addresses[i];
            final isSelected = i == widget.selectedIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => widget.onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primarySurface
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.divider,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        addr.label.toLowerCase() == 'home'
                            ? Icons.home_rounded
                            : addr.label.toLowerCase() == 'office'
                                ? Icons.business_rounded
                                : Icons.place_rounded,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.iconMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(addr.label,
                                style: AppTextStyles.productName.copyWith(
                                  fontSize: 14,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                )),
                            const SizedBox(height: 2),
                            Text(addr.detail,
                                style: AppTextStyles.brandName
                                    .copyWith(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.primary, size: 20),
                      if (!isSelected && widget.addresses.length > 1)
                        GestureDetector(
                          onTap: () {
                            setState(() {});
                            widget.onDelete(i);
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.delete_outline_rounded,
                                color: AppColors.iconMuted, size: 18),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 4),

          // ── Add new address ───────────────────────────────────────────
          if (!_showAddForm)
            GestureDetector(
              onTap: () => setState(() => _showAddForm = true),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.primary, style: BorderStyle.solid),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_location_alt_rounded,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text('Add New Address',
                        style: AppTextStyles.productName
                            .copyWith(color: AppColors.primary, fontSize: 14)),
                  ],
                ),
              ),
            )
          else ...[
            // ── Inline add form ───────────────────────────────────────
            _SheetField(
                controller: _labelCtrl,
                hint: 'Label (e.g. Home, Office)',
                icon: Icons.label_outline_rounded),
            const SizedBox(height: 10),
            _SheetField(
                controller: _detailCtrl,
                hint: 'Full address',
                icon: Icons.place_rounded,
                maxLines: 2),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _showAddForm = false),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: AppColors.divider),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Cancel',
                        style:
                            AppTextStyles.productName.copyWith(fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final label = _labelCtrl.text.trim();
                      final detail = _detailCtrl.text.trim();

                      if (label.isEmpty || detail.isEmpty) return;

                      await widget.onAdd(
                        _Address(
                          label: label,
                          detail: detail,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: Text('Save Address',
                        style:
                            AppTextStyles.buttonFilled.copyWith(fontSize: 14)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Input field for address sheet ─────────────────────────────────────────────

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int maxLines;

  const _SheetField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: AppTextStyles.productName.copyWith(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.brandName.copyWith(fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.iconMuted, size: 18),
        filled: true,
        fillColor: AppColors.primarySurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
