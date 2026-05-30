import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/mega_bottom_nav.dart';
import '../../../post/data/post_repository.dart';

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

  final _postRepository = PostRepository();
  List<String> _feedImages = [];
  List<String> _productImages = [];
  bool _isLoadingPosts = true;
  String username = '';
  String bio = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      final posts = await _postRepository.getPosts();

      setState(() {
        _feedImages = posts
            .where((post) => post.postType == 'regular')
            .map((post) => post.image)
            .toList();

        _productImages = posts
            .where((post) => post.postType == 'product')
            .map((post) => post.image)
            .toList();

        _isLoadingPosts = false;
      });
    } catch (e) {
      setState(() => _isLoadingPosts = false);
    }

    _tabController = TabController(
      length: 2,
      vsync: this,
    );

    loadProfile();
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

    print('UID: ${user.uid}');
    print('BODY: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        username = data['username'] ?? '';
        bio = data['bio'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Icon(
            Icons.location_on_rounded,
            color: AppColors.primary,
            size: 26,
          ),
        ),
        title: Text('MegaShop', style: AppTextStyles.appLogo),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/search'),
            icon: const Icon(
              Icons.search_rounded,
              color: AppColors.iconDefault,
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
                      Icon(Icons.grid_view_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Feed'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_offer_outlined, size: 16),
                      SizedBox(width: 6),
                      Text('Products'),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _isLoadingPosts
                      ? const Center(child: CircularProgressIndicator())
                      : _FeedGrid(images: _feedImages),
                  _isLoadingPosts
                      ? const Center(child: CircularProgressIndicator())
                      : _FeedGrid(images: _productImages),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover + avatar
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Cover photo
            CachedNetworkImage(
              imageUrl:
                  'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=700&q=80',
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (ctx, url) =>
                  Container(height: 160, color: AppColors.primarySurface),
              errorWidget: (ctx, url, err) =>
                  Container(height: 160, color: AppColors.primarySurface),
            ),
            // Avatar — pops out 44px below cover
            Positioned(
              bottom: -44,
              left: 16,
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.primaryLight, AppColors.primary],
                      ),
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl:
                            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&q=80',
                        width: 86,
                        height: 86,
                        fit: BoxFit.cover,
                        placeholder: (ctx, url) =>
                            Container(color: AppColors.primarySurface),
                        errorWidget: (ctx, url, err) =>
                            Container(color: AppColors.primarySurface),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.background,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Edit + Settings — placed BELOW the cover (not overlapping avatar)
        const SizedBox(height: 56), // space for avatar overflow
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final usernameController = TextEditingController();
                  final bioController = TextEditingController();

                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Edit Profile'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: bioController,
                              decoration: const InputDecoration(
                                labelText: 'Bio',
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final user = FirebaseAuth.instance.currentUser;

                              if (user != null) {
                                await http.put(
                                  Uri.parse(
                                    'http://127.0.0.1:8000/users/${user.uid}',
                                  ),
                                  headers: {
                                    'Content-Type': 'application/json',
                                  },
                                  body: jsonEncode({
                                    'username': usernameController.text,
                                    'bio': bioController.text,
                                    'profile_photo': '',
                                  }),
                                );
                              }

                              Navigator.pop(context);
                            },
                            child: const Text('Save'),
                          )
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(Icons.edit_rounded, size: 15),
                label: Text(
                  'Edit Profile',
                  style: AppTextStyles.productName.copyWith(fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();

                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Name + bio
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username.isNotEmpty
                    ? username
                    : FirebaseAuth.instance.currentUser?.email ?? 'Guest',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 4),
              Text(
                bio.isNotEmpty ? bio : 'No bio yet',
                style: AppTextStyles.brandName.copyWith(height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(color: AppColors.divider, height: 1),
        // Stats
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
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
        ),
        const Divider(color: AppColors.divider, height: 1),
      ],
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

  const _FeedGrid({required this.images});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: images.length + 1, // +1 for add post cell
      itemBuilder: (context, i) {
        if (i == images.length) {
          return Container(
            color: AppColors.primarySurface,
            child: const Icon(
              Icons.add_photo_alternate_outlined,
              color: AppColors.primary,
              size: 32,
            ),
          );
        }
        return CachedNetworkImage(
          imageUrl: images[i],
          fit: BoxFit.cover,
          placeholder: (ctx, url) => Container(color: AppColors.primarySurface),
          errorWidget: (ctx, url, err) =>
              Container(color: AppColors.primarySurface),
        );
      },
    );
  }
}
