import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/mega_bottom_nav.dart';
import '../../../../core/services/upload_service.dart';
import '../../data/post_repository.dart';
import '../../../reels/data/reel_repository.dart';
import '../../../product/data/product_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Post creation page — unified single-form design.
///
/// No more separate Regular/Product tabs.
/// User picks the type inline via a toggle chip row.
/// Single upload area for photo/video.
class PostCreationPage extends StatefulWidget {
  const PostCreationPage({super.key});

  @override
  State<PostCreationPage> createState() => _PostCreationPageState();
}

class _PostCreationPageState extends State<PostCreationPage> {
  bool _isProductPost = false;
  bool _isLoading = false;
  bool _hasMedia = false;

  String? _uploadedImageUrl;
  String? _uploadedVideoUrl;
  bool _isVideoPost = false;

  final _captionCtrl = TextEditingController();
  final _productNameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _productRepository = ProductRepository();

  final _postRepository = PostRepository();
  final _uploadService = UploadService();
  final _reelRepository = ReelRepository();

  // Pick image from gallery and upload it to FastAPI upload endpoint
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image == null) return;

    setState(() => _hasMedia = true);

    try {
      final imageUrl = await _uploadService.uploadImage(image);

      setState(() {
        _uploadedImageUrl = imageUrl;
        _uploadedVideoUrl = null;
        _isVideoPost = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _hasMedia = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload image')),
      );
    }
  }

  Future<void> _pickAndUploadVideo() async {
    final picker = ImagePicker();

    final XFile? video = await picker.pickVideo(
      source: ImageSource.gallery,
    );

    if (video == null) return;

    setState(() => _hasMedia = true);

    try {
      final videoUrl = await _uploadService.uploadVideo(video);

      setState(() {
        _uploadedVideoUrl = videoUrl;
        _uploadedImageUrl = 'https://picsum.photos/600/900';
        _isVideoPost = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _hasMedia = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload video')),
      );
    }
  }

  Future<void> _sharePost() async {
    if (_captionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caption cannot be empty')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userName = user?.email?.split('@').first ?? 'User';

      if (_isProductPost) {
        await _productRepository.createProduct(
          name: _productNameCtrl.text.trim(),
          price: int.tryParse(_priceCtrl.text.trim()) ?? 0,
          description: _captionCtrl.text.trim(),
          image: _uploadedImageUrl ?? 'https://picsum.photos/600',
          sellerName: userName,
        );

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
        return;
      }

      if (_isVideoPost && _uploadedVideoUrl != null) {
        await _reelRepository.createReel(
          username: userName,
          userAvatar: 'https://picsum.photos/100',
          productName: _captionCtrl.text.trim(),
          price: 0,
          imageUrl: _uploadedImageUrl ?? 'https://picsum.photos/600/900',
          videoUrl: _uploadedVideoUrl!,
        );

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/reels');
        return;
      }

      await _postRepository.createPost(
        userId: user?.uid ?? 'user_1',
        userName: userName,
        caption: _captionCtrl.text.trim(),
        image: _uploadedImageUrl ?? 'https://picsum.photos/600',
        postType: 'regular',
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to share post')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    _productNameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
        ),
        title: Text(
          'New Post',
          style: AppTextStyles.productName.copyWith(fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _sharePost,
            child: Text(
              _isLoading ? 'Sharing...' : 'Share',
              style: AppTextStyles.buttonOutlined.copyWith(fontSize: 15),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Post type toggle ────────────────────────────────────────
            Row(
              children: [
                _TypeChip(
                  label: 'Regular Post',
                  icon: Icons.image_outlined,
                  isActive: !_isProductPost,
                  onTap: () => setState(() => _isProductPost = false),
                ),
                const SizedBox(width: 10),
                _TypeChip(
                  label: 'Product Post',
                  icon: Icons.local_offer_outlined,
                  isActive: _isProductPost,
                  onTap: () => setState(() => _isProductPost = true),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Upload area ─────────────────────────────────────────────
            GestureDetector(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _hasMedia
                      ? AppColors.primary.withAlpha(20)
                      : AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _hasMedia ? AppColors.primary : AppColors.divider,
                    width: _hasMedia ? 2 : 1.5,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _hasMedia
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _uploadedImageUrl == null
                                ? 'Uploading media...'
                                : 'Media selected',
                            style: AppTextStyles.productName.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to change',
                            style: AppTextStyles.brandName,
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_photo_alternate_outlined,
                              color: AppColors.primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Upload Photo or Video',
                            style: AppTextStyles.sectionTitle.copyWith(
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap to select from gallery',
                            style: AppTextStyles.brandName,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: _pickAndUploadImage,
                                child: _MediaChip(label: '📷 Photo'),
                              ),
                              const SizedBox(width: 8),
                              if (!_isProductPost)
                                GestureDetector(
                                  onTap: _pickAndUploadVideo,
                                  child: _MediaChip(label: '🎬 Video'),
                                ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Caption ─────────────────────────────────────────────────
            TextField(
              controller: _captionCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Write an engaging caption...',
                hintStyle: AppTextStyles.brandName.copyWith(fontSize: 14),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),

            // ── Product fields (only shown for Product Post) ─────────────
            if (_isProductPost) ...[
              const SizedBox(height: 16),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.local_offer_outlined,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Product Details',
                    style: AppTextStyles.productName.copyWith(
                      fontSize: 15,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InlineField(
                controller: _productNameCtrl,
                hint: 'Product name',
                icon: Icons.inventory_2_outlined,
              ),
              const SizedBox(height: 10),
              _InlineField(
                controller: _priceCtrl,
                hint: 'Price (e.g. 99.99)',
                icon: Icons.attach_money_rounded,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],
            const SizedBox(height: 28),

            // ── Extras row ───────────────────────────────────────────────
            Row(
              children: [
                _ExtraButton(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                ),
                const SizedBox(width: 10),
                _ExtraButton(
                  icon: Icons.people_outline_rounded,
                  label: 'Tag people',
                ),
                const SizedBox(width: 10),
                _ExtraButton(
                  icon: Icons.music_note_outlined,
                  label: 'Music',
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: MegaBottomNav(
        currentIndex: 2,
        onTap: (i) {
          switch (i) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/reels');
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

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppColors.textOnPrimary : AppColors.iconDefault,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.categoryActive.copyWith(
                color:
                    isActive ? AppColors.textOnPrimary : AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaChip extends StatelessWidget {
  final String label;

  const _MediaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        label,
        style: AppTextStyles.brandName.copyWith(fontSize: 12),
      ),
    );
  }
}

class _InlineField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;

  const _InlineField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.brandName.copyWith(fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.iconMuted, size: 20),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}

class _ExtraButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ExtraButton({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.iconMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.brandName.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
