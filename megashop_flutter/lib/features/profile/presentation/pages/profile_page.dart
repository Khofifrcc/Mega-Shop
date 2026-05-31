import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/mega_bottom_nav.dart';
import '../../../home/domain/entities/product.dart';

/// Profile page matching the mockup.
///
/// Features: cover photo + overlapping avatar with online dot,
/// edit profile button, stats row (Followers/Following/Posts/Products),
/// Feed/Products tab, and a 3-column photo grid.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String username = '';
  String bio = '';
  List<Product> _products = [];
  List<String> _reelVideos = [];
  bool _isLoadingProfileData = true;

  final _feedImages = [
    'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=300&q=80',
    'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=300&q=80',
    'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=300&q=80',
    'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=300&q=80',
    'https://images.unsplash.com/photo-1524592094714-0f0654e20314?w=300&q=80',
  ];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
    );

    loadProfile();
    loadUserUploads();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final response = await http.get(
      Uri.parse(
        'http://127.0.0.1:8000/users/${user.uid}',
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        username = data['username'] ?? '';
        bio = data['bio'] ?? '';
      });
    }
  }

  Future<void> loadUserUploads() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final productResponse = await http.get(
        Uri.parse('http://127.0.0.1:8000/products/user/${user.uid}'),
      );

      final reelResponse = await http.get(
        Uri.parse('http://127.0.0.1:8000/reels/user/${user.uid}'),
      );

      final products = productResponse.statusCode == 200
          ? jsonDecode(productResponse.body) as List
          : [];

      final reels = reelResponse.statusCode == 200
          ? jsonDecode(reelResponse.body) as List
          : [];

      if (mounted) {
        setState(() {
          _products = products.map((item) {
            return Product(
              id: item['id'].toString(),
              name: item['name'] ?? 'Product',
              brand: item['user_id'] ?? 'MegaShop',
              price: (item['price'] as num).toDouble(),
              imageUrl: item['image'] ?? '',
              description: item['description'] ?? '',
            );
          }).toList();

          _reelVideos = reels
              .map((item) => item['video']?.toString() ?? '')
              .where((url) => url.isNotEmpty)
              .toList();

          _isLoadingProfileData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProfileData = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: null,
        title: Text('MegaShop', style: AppTextStyles.appLogo),
        centerTitle: true,
        actions: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: IconButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (route) => false);
                }
              },
              icon: const Icon(
                CupertinoIcons.square_arrow_right,
                color: AppColors.primary,
              ),
              tooltip: 'Sign out',
            ),
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(child: _buildHeader(context)),
        ],
        body: Column(
          children: [
            // Tab bar
            TabBar(
              controller: _tabController,
              labelStyle: AppTextStyles.categoryActive.copyWith(
                color: AppColors.primary,
              ),
              unselectedLabelStyle: AppTextStyles.categoryInactive,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              dividerColor: AppColors.divider,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.square_grid_2x2_fill, size: 16),
                      SizedBox(width: 6),
                      Text('Products'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.play_circle_fill, size: 16),
                      SizedBox(width: 6),
                      Text('Reels'),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _isLoadingProfileData
                      ? const Center(child: CircularProgressIndicator())
                      : _ProductGrid(products: _products),
                  _isLoadingProfileData
                      ? const Center(child: CircularProgressIndicator())
                      : _ReelsGrid(videos: _reelVideos),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: MegaBottomNav(
        currentIndex: 4,
        onTap: (i) {
          switch (i) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/reels');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/post');
              break;
            case 3:
              Navigator.pushNamed(context, '/cart');
              break;
          }
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        children: [
          // Avatar centered with gradient ring
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
                  imageUrl:
                      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&q=80',
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  placeholder: (ctx, url) =>
                      Container(color: AppColors.primarySurface),
                  errorWidget: (ctx, url, err) =>
                      Container(color: AppColors.primarySurface),
                ),
              ),
              // Online dot
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 2.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Name
          Text(
            username.isNotEmpty
                ? username
                : FirebaseAuth.instance.currentUser?.email ?? 'Guest',
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),

          // Bio
          Text(
            bio.isNotEmpty ? bio : 'No bio yet · MegaShop Member',
            style: AppTextStyles.brandName.copyWith(fontSize: 13, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Edit Profile button
          OutlinedButton.icon(
            onPressed: () {
              final usernameController = TextEditingController();
              final bioController = TextEditingController();
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Edit Profile'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: usernameController,
                        decoration:
                            const InputDecoration(labelText: 'Username'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: bioController,
                        decoration: const InputDecoration(labelText: 'Bio'),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          await http.put(
                            Uri.parse(
                                'http://127.0.0.1:8000/users/${user.uid}'),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({
                              'username': usernameController.text,
                              'bio': bioController.text,
                              'profile_photo': '',
                            }),
                          );
                        }
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(CupertinoIcons.pencil, size: 15),
            label: Text('Edit Profile',
                style: AppTextStyles.productName.copyWith(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            ),
          ),
          const SizedBox(height: 20),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              _StatItem(value: '12.4k', label: 'Followers'),
              _Separator(),
              _StatItem(value: '842', label: 'Following'),
              _Separator(),
              _StatItem(value: '340', label: 'Posts'),
              _Separator(),
              _StatItem(value: '56', label: 'Products'),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider, height: 1),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.sectionTitle.copyWith(fontSize: 18)),
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

class _FeedGrid extends StatelessWidget {
  final List<String> images;
  final bool isReels;

  const _FeedGrid({required this.images, this.isReels = false});

  bool _isVideo(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.mp4') ||
        lower.contains('.mov') ||
        lower.contains('.webm');
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: images.length,
      itemBuilder: (context, i) {
        final isVideo = _isVideo(images[i]);

        return Stack(
          fit: StackFit.expand,
          children: [
            isVideo
                ? Container(
                    color: Colors.black,
                    child: const Center(
                      child: Icon(
                        CupertinoIcons.play_circle_fill,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: images[i],
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) =>
                        Container(color: AppColors.primarySurface),
                    errorWidget: (ctx, url, err) =>
                        Container(color: AppColors.primarySurface),
                  ),
            if (isVideo || isReels) ...[
              Positioned(
                bottom: 8,
                left: 8,
                child: Row(
                  children: const [
                    Icon(
                      CupertinoIcons.play_fill,
                      color: Colors.white,
                      size: 12,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Video',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ReelsGrid extends StatelessWidget {
  final List<String> videos;

  const _ReelsGrid({required this.videos});

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return Center(
        child: Text(
          'No reels yet',
          style: AppTextStyles.brandName,
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: videos.length,
      itemBuilder: (context, i) {
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/reels');
          },
          child: Container(
            color: Colors.black,
            child: const Center(
              child: Icon(
                CupertinoIcons.play_circle_fill,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final List<Product> products;

  const _ProductGrid({required this.products});

  bool _isVideo(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.mp4') ||
        lower.contains('.mov') ||
        lower.contains('.webm');
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: products.length,
      itemBuilder: (context, i) {
        final product = products[i];
        final isVideo = _isVideo(product.imageUrl);

        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/product', arguments: product);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              isVideo
                  ? Container(
                      color: Colors.black,
                      child: const Center(
                        child: Icon(
                          CupertinoIcons.play_circle_fill,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) =>
                          Container(color: AppColors.primarySurface),
                      errorWidget: (ctx, url, err) =>
                          Container(color: AppColors.primarySurface),
                    ),
              if (isVideo)
                const Positioned(
                  bottom: 8,
                  left: 8,
                  child: Text(
                    '▶ Video',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
