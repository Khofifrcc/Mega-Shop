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

  bool _isUploading = false;

  String _selectedCategory = 'Fashion';
  final List<String> _categories = ['Fashion', 'Tech', 'Home', 'Beauty'];

  // Selected media can be product image or reels video
  List<XFile> _selectedImages = [];
  XFile? _selectedVideo;

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

    if (_mediaType == 'Photo') {
      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 80,
      );
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } else {
      final video = await picker.pickVideo(
        source: ImageSource.gallery,
      );
      if (video != null) {
        setState(() {
          _selectedVideo = video;
        });
      }
    }
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
        (_mediaType == 'Photo' && _selectedImages.isEmpty) ||
        (_mediaType == 'Video' && _selectedVideo == null)) {
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

      String heroImageUrl = '';
      List<String> allImageUrls = [];
      String mediaUrl = ''; // For video if used later

      if (_mediaType == 'Photo') {
        for (var image in _selectedImages) {
          final fileName = '$folder/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_${image.name}';
          final ref = FirebaseStorage.instance.ref().child(fileName);

          if (kIsWeb) {
            final bytes = await image.readAsBytes();
            await ref.putData(bytes);
          } else {
            await ref.putFile(File(image.path));
          }

          final url = await ref.getDownloadURL();
          allImageUrls.add(url);
        }
        if (allImageUrls.isNotEmpty) {
          heroImageUrl = allImageUrls.first;
        }
      } else {
        final fileName = '$folder/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.mp4';
        final ref = FirebaseStorage.instance.ref().child(fileName);

        if (kIsWeb) {
          final bytes = await _selectedVideo!.readAsBytes();
          await ref.putData(bytes);
        } else {
          await ref.putFile(File(_selectedVideo!.path));
        }

        mediaUrl = await ref.getDownloadURL();
      }

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
          'category': _selectedCategory,
          'mediaType': 'Photo',
          'imageUrl': heroImageUrl,
          'imageUrls': allImageUrls,
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
                      _selectedImages.clear();
                      _selectedVideo = null;
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
                      _selectedImages.clear();
                      _selectedVideo = null;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Upload area
            if (_mediaType == 'Photo' && _selectedImages.isNotEmpty)
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _selectedImages.length) {
                      return GestureDetector(
                        onTap: _pickMedia,
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary, width: 1.5),
                          ),
                          child: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 32),
                        ),
                      );
                    }
                    final image = _selectedImages[index];
                    return Stack(
                      children: [
                        Container(
                          width: 140,
                          margin: EdgeInsets.only(right: index == _selectedImages.length - 1 ? 0 : 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: kIsWeb
                                ? Image.network(image.path, fit: BoxFit.cover, height: 140, width: 140)
                                : Image.file(File(image.path), fit: BoxFit.cover, height: 140, width: 140),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: index == _selectedImages.length - 1 ? 4 : 12,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImages.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              )
            else if (_mediaType == 'Video' && _selectedVideo != null)
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.video_file_rounded, color: AppColors.primary, size: 54),
                    const SizedBox(height: 12),
                    Text('Video selected', style: AppTextStyles.sectionTitle.copyWith(fontSize: 17)),
                  ],
                ),
              )
            else
              GestureDetector(
                onTap: _pickMedia,
                child: Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.divider, width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _mediaType == 'Photo' ? Icons.add_photo_alternate_outlined : Icons.video_call_outlined,
                        color: AppColors.primary,
                        size: 42,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _mediaType == 'Photo' ? 'Upload Product Photos' : 'Upload Reels Video',
                        style: AppTextStyles.sectionTitle.copyWith(fontSize: 17),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _mediaType == 'Photo' ? 'Tap to select images from gallery' : 'Tap to select an MP4 video clip',
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
            const SizedBox(height: 10),

            if (_mediaType == 'Photo') ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.category_outlined, color: AppColors.iconMuted, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          dropdownColor: AppColors.surface,
                          style: AppTextStyles.brandName.copyWith(fontSize: 14),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.iconMuted),
                          items: _categories.map((cat) {
                            return DropdownMenuItem<String>(
                              value: cat,
                              child: Text(cat),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedCategory = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

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
