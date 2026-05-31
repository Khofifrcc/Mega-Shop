import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/mega_bottom_nav.dart';

class PostCreationPage extends StatefulWidget {
  const PostCreationPage({super.key});

  @override
  State<PostCreationPage> createState() => _PostCreationPageState();
}

class _PostCreationPageState extends State<PostCreationPage> {
  String _mediaType = 'Photo'; // Photo / Video
  bool _isProductReel = false;

  final _captionCtrl = TextEditingController();
  final _productNameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  bool _hasMedia = false;
  bool _isLoading = false;

  XFile? _pickedMedia;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _captionCtrl.dispose();
    _productNameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    XFile? file;

    if (_mediaType == 'Photo') {
      file = await _picker.pickImage(source: ImageSource.gallery);
    } else {
      file = await _picker.pickVideo(source: ImageSource.gallery);
    }

    if (file != null) {
      setState(() {
        _pickedMedia = file;
        _hasMedia = true;
      });
    }
  }

  Future<void> _shareToApi() async {
    final name = _productNameCtrl.text.trim();
    final description = _captionCtrl.text.trim();
    final price = int.tryParse(_priceCtrl.text.trim()) ?? 0;
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add description')),
      );
      return;
    }

    if ((_mediaType == 'Photo' || _isProductReel) &&
        (name.isEmpty || price <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product name and price are required')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      String mediaUrl = 'https://picsum.photos/500';

      if (_pickedMedia != null) {
        final uploadRequest = http.MultipartRequest(
          'POST',
          Uri.parse('http://127.0.0.1:8000/upload'),
        );

        final bytes = await _pickedMedia!.readAsBytes();

        uploadRequest.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: _pickedMedia!.name,
          ),
        );

        final uploadResponse = await uploadRequest.send();
        final uploadBody = await uploadResponse.stream.bytesToString();

        if (uploadResponse.statusCode >= 400) {
          throw Exception('Upload failed: $uploadBody');
        }

        final uploadJson = jsonDecode(uploadBody);
        mediaUrl = uploadJson['url'];
      }

      if (_mediaType == 'Photo') {
        final productResponse = await http.post(
          Uri.parse('http://127.0.0.1:8000/products/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'name': name,
            'price': price,
            'description': description,
            'image': mediaUrl,
          }),
        );

        if (productResponse.statusCode >= 400) {
          throw Exception('Product API Error: ${productResponse.body}');
        }

        final postResponse = await http.post(
          Uri.parse('http://127.0.0.1:8000/posts/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'caption': description,
            'image': mediaUrl,
          }),
        );

        if (postResponse.statusCode >= 400) {
          throw Exception('Post API Error: ${postResponse.body}');
        }
      } else {
        final reelResponse = await http.post(
          Uri.parse('http://127.0.0.1:8000/reels/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'caption': description,
            'video': mediaUrl,
            'is_product': _isProductReel,
            'product_name': _isProductReel ? name : '',
            'price': _isProductReel ? price : 0,
            'image': _isProductReel ? mediaUrl : '',
          }),
        );

        if (reelResponse.statusCode >= 400) {
          throw Exception('Reel API Error: ${reelResponse.body}');
        }

        if (_isProductReel) {
          final productResponse = await http.post(
            Uri.parse('http://127.0.0.1:8000/products/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'name': name,
              'price': price,
              'description': description,
              'image': mediaUrl,
            }),
          );

          if (productResponse.statusCode >= 400) {
            throw Exception('Product API Error: ${productResponse.body}');
          }
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mediaType == 'Photo'
                ? 'Product shared successfully!'
                : _isProductReel
                    ? 'Product Reels shared successfully!'
                    : 'Reels shared successfully!',
          ),
          backgroundColor: AppColors.primary,
        ),
      );

      Navigator.pushReplacementNamed(
        context,
        _mediaType == 'Photo' ? '/home' : '/reels',
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Share failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showProductFields = _mediaType == 'Photo' || _isProductReel;

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
            onPressed: _isLoading ? null : _shareToApi,
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
            Text(
              'Media Type',
              style: AppTextStyles.productName.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
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
                      _isProductReel = false;
                      _hasMedia = false;
                      _pickedMedia = null;
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
                      _isProductReel = false;
                      _hasMedia = false;
                      _pickedMedia = null;
                    });
                  },
                ),
              ],
            ),
            if (_mediaType == 'Video') ...[
              const SizedBox(height: 14),
              Text(
                'Reels Type',
                style: AppTextStyles.productName.copyWith(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _TypeChip(
                    label: 'Reels Only',
                    icon: Icons.play_circle_outline,
                    isActive: !_isProductReel,
                    onTap: () => setState(() => _isProductReel = false),
                  ),
                  const SizedBox(width: 10),
                  _TypeChip(
                    label: 'Product Reels',
                    icon: Icons.shopping_bag_outlined,
                    isActive: _isProductReel,
                    onTap: () => setState(() => _isProductReel = true),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Text(
              _mediaType == 'Photo'
                  ? '• Photo uploads will appear in Home and Profile Products.'
                  : _isProductReel
                      ? '• Product Reels will appear in Reels and Home products.'
                      : '• Reels Only will appear in Reels and Profile Reels.',
              style: AppTextStyles.brandName.copyWith(
                color: AppColors.primary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
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
                            _mediaType == 'Photo'
                                ? 'Photo media selected'
                                : 'Video media selected',
                            style: AppTextStyles.productName.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _pickedMedia?.name ?? 'Tap to change media file',
                            style: AppTextStyles.brandName,
                          ),
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
            if (showProductFields) ...[
              Row(
                children: [
                  const Icon(
                    Icons.local_offer_outlined,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Product Information',
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 20),
            ],
            Text(
              _mediaType == 'Video' && !_isProductReel
                  ? 'Reels Description'
                  : 'Product Description',
              style: AppTextStyles.productName.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _captionCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: _mediaType == 'Video' && !_isProductReel
                    ? 'Write a caption for your reels...'
                    : 'Write product details or caption...',
                hintStyle: AppTextStyles.brandName.copyWith(fontSize: 14),
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
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
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
              Icon(
                icon,
                size: 16,
                color:
                    isActive ? AppColors.textOnPrimary : AppColors.iconDefault,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.categoryActive.copyWith(
                  color: isActive
                      ? AppColors.textOnPrimary
                      : AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
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
      ),
    );
  }
}
