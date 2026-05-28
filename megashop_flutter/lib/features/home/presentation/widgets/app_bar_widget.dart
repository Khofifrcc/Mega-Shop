import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Custom AppBar for the MegaShop home screen.
///
/// Displays the location icon on the left, "MegaShop" title in the center,
/// and action icons (search, chat with unread dot, cart) on the right.
class MegaShopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int cartItemCount;
  final VoidCallback? onSearchTap;
  final VoidCallback? onChatTap;
  final VoidCallback? onCartTap;

  const MegaShopAppBar({
    super.key,
    this.cartItemCount = 0,
    this.onSearchTap,
    this.onChatTap,
    this.onCartTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leadingWidth: 48,
      leading: const Padding(
        padding: EdgeInsets.only(left: 16),
        child: Icon(
          Icons.location_on_rounded,
          color: AppColors.primary,
          size: 26,
        ),
      ),
      title: Text('MegaShop', style: AppTextStyles.appLogo),
      actions: [
        // Search icon
        _AppBarIcon(
          icon: Icons.search_rounded,
          onTap: onSearchTap,
        ),
        // Chat icon with unread dot
        Stack(
          alignment: Alignment.center,
          children: [
            _AppBarIcon(
              icon: Icons.chat_bubble_outline_rounded,
              onTap: onChatTap,
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.badgeSale,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        // Cart icon with count badge
        Stack(
          alignment: Alignment.center,
          children: [
            _AppBarIcon(
              icon: Icons.shopping_cart_outlined,
              onTap: onCartTap,
            ),
            if (cartItemCount > 0)
              Positioned(
                top: 10,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$cartItemCount',
                    style: AppTextStyles.badge.copyWith(fontSize: 9),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

/// Small tappable icon used in the AppBar.
class _AppBarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _AppBarIcon({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: Icon(icon, color: AppColors.iconDefault, size: 24),
      ),
    );
  }
}
