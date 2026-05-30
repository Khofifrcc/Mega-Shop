import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Custom AppBar for the MegaShop home screen.
///
/// Displays the location icon on the left, "MegaShop" title in the center,
/// and action icons (search, chat with unread dot) on the right.
class MegaShopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onChatTap;
  final VoidCallback? onLocationTap;

  const MegaShopAppBar({
    super.key,
    this.onSearchTap,
    this.onChatTap,
    this.onLocationTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leadingWidth: 48,
      leading: _AppBarIcon(
        icon: Icons.location_on_rounded,
        onTap: onLocationTap,
        color: AppColors.primary,
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
        const SizedBox(width: 8),
      ],
    );
  }
}

/// Small tappable icon used in the AppBar.
/// Uses [InkWell] so hover cursor shows as pointer on web/desktop.
class _AppBarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  const _AppBarIcon({
    required this.icon,
    this.onTap,
    this.color = AppColors.iconDefault,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: AppColors.primary.withValues(alpha: 0.12),
        highlightColor: AppColors.primary.withValues(alpha: 0.06),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Icon(icon, color: color, size: 24),
          ),
        ),
      ),
    );
  }
}
