import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/mega_bottom_nav.dart';

/// Post creation page — unified single-form design.
///
/// Handles posting photos for the product catalog and videos for Reels.
/// Includes price, name, description, and details.
class PostCreationPage extends StatefulWidget {
  const PostCreationPage({super.key});

  @override
  State<PostCreationPage> createState() => _PostCreationPageState();
}

class _PostCreationPageState extends State<PostCreationPage> {
  String _mediaType = 'Photo'; // 'Photo' or 'Video'
  final _captionCtrl = TextEditingController();
  final _productNameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  bool _hasMedia = false;

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
        leading: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          ),
        ),
        title: Text('Create Product Listing', style: AppTextStyles.productName.copyWith(fontSize: 18)),
        centerTitle: true,
        actions: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/home');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_mediaType == 'Photo'
                        ? 'Product shared successfully!'
                        : 'Reels video shared successfully!'),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Text('Share',
                  style: AppTextStyles.buttonOutlined.copyWith(fontSize: 15)),
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
            // ── Upload Type Selector (Photo vs Video) ──────────────────
            Text('Media Type',
                style: AppTextStyles.productName.copyWith(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                _TypeChip(
                  label: 'Product Photo',
                  icon: Icons.photo_library_outlined,
                  isActive: _mediaType == 'Photo',
                  onTap: () => setState(() => _mediaType = 'Photo'),
                ),
                const SizedBox(width: 10),
                _TypeChip(
                  label: 'Reels Video',
                  icon: Icons.video_library_outlined,
                  isActive: _mediaType == 'Video',
                  onTap: () => setState(() => _mediaType = 'Video'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _mediaType == 'Photo'
                  ? '• Photo uploads will be displayed on the home product grids.'
                  : '• Video uploads will play on the full-screen Reels tab feed.',
              style: AppTextStyles.brandName.copyWith(color: AppColors.primary, fontSize: 12),
            ),
            const SizedBox(height: 20),

            // ── Upload area ─────────────────────────────────────────────
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() => _hasMedia = !_hasMedia),
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
                      color: _hasMedia
                          ? AppColors.primary
                          : AppColors.divider,
                      width: _hasMedia ? 2 : 1.5,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _hasMedia
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.primary, size: 48),
                            const SizedBox(height: 12),
                            Text(
                                _mediaType == 'Photo'
                                    ? 'Photo media selected'
                                    : 'Reels Video clip selected',
                                style: AppTextStyles.productName
                                    .copyWith(color: AppColors.primary)),
                            const SizedBox(height: 4),
                            Text('Tap to change media file',
                                style: AppTextStyles.brandName),
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
                              child: Icon(
                                  _mediaType == 'Photo'
                                      ? Icons.add_photo_alternate_outlined
                                      : Icons.video_call_outlined,
                                  color: AppColors.primary,
                                  size: 32),
                            ),
                            const SizedBox(height: 14),
                            Text(
                                _mediaType == 'Photo'
                                    ? 'Upload Product Photo'
                                    : 'Upload Reels Video',
                                style: AppTextStyles.sectionTitle
                                    .copyWith(fontSize: 17)),
                            const SizedBox(height: 6),
                            Text(
                                _mediaType == 'Photo'
                                    ? 'Tap to select an image from gallery'
                                    : 'Tap to select an MP4 video clip',
                                style: AppTextStyles.brandName),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Product Details section (always visible) ────────────────
            Row(
              children: [
                const Icon(Icons.local_offer_outlined,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text('Product Information',
                    style: AppTextStyles.productName
                        .copyWith(fontSize: 15, color: AppColors.primary)),
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

            // ── Caption ─────────────────────────────────────────────────
            Text('Product Description',
                style: AppTextStyles.productName.copyWith(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _captionCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Write an engaging details description or caption...',
                hintStyle: AppTextStyles.brandName.copyWith(fontSize: 14),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.divider),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),

            // ── Extras row ───────────────────────────────────────────────
            Row(
              children: [
                _ExtraButton(
                    icon: Icons.location_on_outlined, label: 'Location'),
                const SizedBox(width: 10),
                _ExtraButton(
                    icon: Icons.people_outline_rounded, label: 'Tag people'),
                const SizedBox(width: 10),
                _ExtraButton(icon: Icons.music_note_outlined, label: 'Music'),
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color:
                isActive ? AppColors.primary : AppColors.surface,
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

class _ExtraButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ExtraButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
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
              Text(label,
                  style:
                      AppTextStyles.brandName.copyWith(fontSize: 12)),
          ],
        ),
      ),
    ),
    );
  }
}
