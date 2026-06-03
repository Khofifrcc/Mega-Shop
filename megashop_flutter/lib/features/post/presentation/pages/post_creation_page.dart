import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/mega_bottom_nav.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PostCreationPage extends StatefulWidget {
  const PostCreationPage({super.key});

  @override
  State<PostCreationPage> createState() => _PostCreationPageState();
}

class _PostCreationPageState extends State<PostCreationPage> {
  String _mediaType = 'Photo'; // Photo = product, Video = reels

  final _captionCtrl = TextEditingController();
  final _productNameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  bool _hasMedia = false;
  bool _isUploading = false;

  // Selected media can be product image or reels video
  XFile? _selectedMedia;

  @override
  void dispose() {
    _captionCtrl.dispose();
    _productNameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  // Pick media based on selected type
  Future<void> _pickMedia() async {
    final picker = ImagePicker();

    final media = _mediaType == 'Photo'
        ? await picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 80,
          )
        : await picker.pickVideo(
            source: ImageSource.gallery,
          );

    if (media == null) return;

    setState(() {
      _selectedMedia = media;
      _hasMedia = true;
    });
  }

  // Share product photo or reels video
  Future<void> _sharePost() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first.')),
      );
      return;
    }

    final productName = _productNameCtrl.text.trim();
    final priceText = _priceCtrl.text.trim();
    final description = _captionCtrl.text.trim();
    final price = double.tryParse(priceText);

    if (productName.isEmpty ||
        priceText.isEmpty ||
        description.isEmpty ||
        _selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all fields and select media.')),
      );
      return;
    }

    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price.')),
      );
      return;
    }

    try {
      setState(() => _isUploading = true);

      // Upload selected file to Firebase Storage
      final folder = _mediaType == 'Photo' ? 'products' : 'reels';
      final extension = _mediaType == 'Photo' ? 'jpg' : 'mp4';

      final fileName =
          '$folder/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.$extension';

      final ref = FirebaseStorage.instance.ref().child(fileName);

      if (kIsWeb) {
        final bytes = await _selectedMedia!.readAsBytes();
        await ref.putData(bytes);
      } else {
        await ref.putFile(File(_selectedMedia!.path));
      }

      final mediaUrl = await ref.getDownloadURL();

      // Get latest user profile data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data();
      final ownerUsername =
          userData?['username'] ?? user.email?.split('@')[0] ?? 'Seller';
      final userAvatar = userData?['profileImageUrl'] ?? '';

      // Save photo product to products collection
      if (_mediaType == 'Photo') {
        await FirebaseFirestore.instance.collection('products').add({
          'ownerId': user.uid,
          'ownerEmail': user.email,
          'ownerUsername': ownerUsername,
          'ownerAvatar': userAvatar,
          'name': productName,
          'price': price,
          'description': description,
          'mediaType': 'Photo',
          'imageUrl': mediaUrl,
          'videoUrl': '',
          'likes': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Save video post only to reels collection
// Reels will appear only in Reels page, Reels section in profile,
// and not in Home product grid.
      if (_mediaType == 'Video') {
        await FirebaseFirestore.instance.collection('reels').add({
          'ownerId': user.uid,
          'username': ownerUsername,
          'userAvatar': userAvatar,
          'caption': description,
          'productName': productName,
          'price': price,
          'originalPrice': null,
          'imageUrl': '',
          'videoUrl': mediaUrl,
          'likeCount': 0,
          'commentCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mediaType == 'Photo'
                ? 'Product shared successfully!'
                : 'Reels video shared successfully!',
          ),
          backgroundColor: AppColors.primary,
        ),
      );

      // Go to the correct page after upload
      Navigator.pushReplacementNamed(
        context,
        _mediaType == 'Photo' ? '/home' : '/reels',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
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
          'Create Product Listing',
          style: AppTextStyles.productName.copyWith(fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _sharePost,
            child: _isUploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Share',
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
            Text('Media Type',
                style: AppTextStyles.productName
                    .copyWith(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 8),

            Row(
              children: [
                _TypeChip(
                  label: 'Product Photo',
                  icon: Icons.photo_library_outlined,
                  isActive: _mediaType == 'Photo',
                  onTap: () {
                    setState(() {
                      _mediaType = 'Photo';
                      _selectedMedia = null;
                      _hasMedia = false;
                    });
                  },
                ),
                const SizedBox(width: 10),
                _TypeChip(
                  label: 'Reels Video',
                  icon: Icons.video_library_outlined,
                  isActive: _mediaType == 'Video',
                  onTap: () {
                    setState(() {
                      _mediaType = 'Video';
                      _selectedMedia = null;
                      _hasMedia = false;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Upload area
            GestureDetector(
              onTap: _pickMedia,
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
                  ),
                ),
                child: _selectedMedia != null
                    ? _mediaType == 'Photo'
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: kIsWeb
                                ? Image.network(
                                    _selectedMedia!.path,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  )
                                : Image.file(
                                    File(_selectedMedia!.path),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.video_file_rounded,
                                  color: AppColors.primary, size: 54),
                              const SizedBox(height: 12),
                              Text('Video selected',
                                  style: AppTextStyles.sectionTitle
                                      .copyWith(fontSize: 17)),
                            ],
                          )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _mediaType == 'Photo'
                                ? Icons.add_photo_alternate_outlined
                                : Icons.video_call_outlined,
                            color: AppColors.primary,
                            size: 42,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _mediaType == 'Photo'
                                ? 'Upload Product Photo'
                                : 'Upload Reels Video',
                            style: AppTextStyles.sectionTitle
                                .copyWith(fontSize: 17),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _mediaType == 'Photo'
                                ? 'Tap to select an image from gallery'
                                : 'Tap to select an MP4 video clip',
                            style: AppTextStyles.brandName,
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 24),

            Text('Product Information',
                style: AppTextStyles.productName
                    .copyWith(fontSize: 15, color: AppColors.primary)),
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
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 20),

            Text('Product Description',
                style: AppTextStyles.productName
                    .copyWith(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 8),

            TextField(
              controller: _captionCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Write description or caption...',
                hintStyle: AppTextStyles.brandName.copyWith(fontSize: 14),
                filled: true,
                fillColor: AppColors.surface,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
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
              Icon(icon,
                  size: 16,
                  color: isActive
                      ? AppColors.textOnPrimary
                      : AppColors.iconDefault),
              const SizedBox(width: 6),
              Text(label,
                  style: AppTextStyles.categoryActive.copyWith(
                      color: isActive
                          ? AppColors.textOnPrimary
                          : AppColors.textPrimary,
                      fontSize: 13)),
            ],
          ),
        ),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
