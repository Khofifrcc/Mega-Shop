import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/mega_bottom_nav.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  String profileImageUrl = '';
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();

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

//chane profil pict
  Future<void> _changeProfilePhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return;

    try {
      setState(() => _isUploadingPhoto = true);

      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('${user.uid}.jpg');

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        await ref.putData(bytes);
      } else {
        await ref.putFile(File(image.path));
      }

      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'profileImageUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() => profileImageUrl = url);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo changed successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile photo upload failed: $e'),
            backgroundColor: AppColors.badgeSale,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<void> loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data();

    if (data != null && mounted) {
      setState(() {
        username = data['username'] ?? '';
        bio = data['bio'] ?? '';
        profileImageUrl = data['profileImageUrl'] ?? '';
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
                  const _MyProductsGrid(),
                  const _MyReelsGrid(),
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
              Positioned(
                bottom: -2,
                right: -2,
                child: GestureDetector(
                  onTap: _changeProfilePhoto,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.background,
                        width: 2,
                      ),
                    ),
                    child: _isUploadingPhoto
                        ? const Padding(
                            padding: EdgeInsets.all(6),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                  ),
                ),
              ),
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
                child: profileImageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: profileImageUrl,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        placeholder: (ctx, url) => Container(
                          color: AppColors.primarySurface,
                        ),
                        errorWidget: (ctx, url, err) => Container(
                          color: AppColors.primarySurface,
                          child: const Icon(Icons.person, size: 40),
                        ),
                      )
                    : Container(
                        width: 90,
                        height: 90,
                        color: AppColors.primarySurface,
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: AppColors.primary,
                        ),
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
              Positioned(
                bottom: -2,
                right: -2,
                child: GestureDetector(
                  onTap: _changeProfilePhoto,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.background,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
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
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .update({
                            'username': usernameController.text.trim(),
                            'bio': bioController.text.trim(),
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                          final productDocs = await FirebaseFirestore.instance
                              .collection('products')
                              .where('ownerId', isEqualTo: user.uid)
                              .get();

                          for (final doc in productDocs.docs) {
                            await doc.reference.update({
                              'ownerUsername': usernameController.text.trim(),
                            });
                          }

                          if (mounted) {
                            setState(() {
                              username = usernameController.text.trim();
                              bio = bioController.text.trim();
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profile updated successfully!'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
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

class _MyProductsGrid extends StatelessWidget {
  const _MyProductsGrid();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text('Please login first.'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('ownerId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: AppTextStyles.brandName,
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No products uploaded yet.',
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
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final imageUrl = data['imageUrl'] ?? '';
            final product = Product(
              id: docs[i].id,
              ownerId: data['ownerId'] ?? '',
              name: data['name'] ?? '',
              brand: data['ownerUsername'] ?? data['ownerEmail'] ?? 'Seller',
              description: data['description'] ?? '',
              price: (data['price'] ?? 0).toDouble(),
              imageUrl: imageUrl,
              badge: data['mediaType'] == 'Photo' ? 'NEW' : null,
            );

            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/product',
                  arguments: product,
                );
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) =>
                        Container(color: AppColors.primarySurface),
                    errorWidget: (ctx, url, err) => Container(
                      color: AppColors.primarySurface,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.iconMuted,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 6,
                    right: 6,
                    bottom: 6,
                    child: Text(
                      data['name'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _MyReelsGrid extends StatelessWidget {
  const _MyReelsGrid();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reels')
          .where('ownerId', isEqualTo: user!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(
            child: Text('No reels uploaded yet'),
          );
        }

        return GridView.builder(
            padding: const EdgeInsets.all(1),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/reels',
                  );
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: data['userAvatar'] ?? '',
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: Colors.black12),
                      errorWidget: (_, __, ___) =>
                          Container(color: Colors.black12),
                    ),
                    Container(
                      color: Colors.black26,
                    ),
                    const Center(
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            });
      },
    );
  }
}
