import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Custom AppBar for the MegaShop home screen.
///
/// Displays the notification icon on the left, "MegaShop" title in the center,
/// and action icons (search, chat with unread dot) on the right.
class MegaShopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onChatTap;
  final VoidCallback? onNotificationTap;

  const MegaShopAppBar({
    super.key,
    this.onSearchTap,
    this.onChatTap,
    this.onNotificationTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leadingWidth: 48,
      leading: _NotificationIcon(userId: userId, onTap: onNotificationTap),
      title: Text('MegaShop', style: AppTextStyles.appLogo),
      actions: [
        // Search icon
        _AppBarIcon(
          icon: Icons.search_rounded,
          onTap: onSearchTap,
        ),
        _ChatIcon(userId: userId, onTap: onChatTap),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  final String? userId;
  final VoidCallback? onTap;

  const _NotificationIcon({required this.userId, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return _IconWithDot(
        icon: Icons.notifications_none_rounded,
        color: AppColors.primary,
        showDot: false,
        onTap: onTap,
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data();
        final lastSeen = userData?['notificationsLastSeenAt'];

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('participants', arrayContains: userId)
              .snapshots(),
          builder: (context, orderSnapshot) {
            final hasUnreadOrder = (orderSnapshot.data?.docs ?? []).any((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final createdAt = data['createdAt'];

              if (createdAt is! Timestamp) return false;
              if (lastSeen is! Timestamp) return true;
              return createdAt.compareTo(lastSeen) > 0;
            });

            return _IconWithDot(
              icon: Icons.notifications_none_rounded,
              color: AppColors.primary,
              showDot: hasUnreadOrder,
              dotColor: AppColors.notifBadge,
              onTap: onTap,
            );
          },
        );
      },
    );
  }
}

class _ChatIcon extends StatelessWidget {
  final String? userId;
  final VoidCallback? onTap;

  const _ChatIcon({required this.userId, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return _IconWithDot(
        icon: Icons.chat_bubble_outline_rounded,
        showDot: false,
        onTap: onTap,
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('members', arrayContains: userId)
          .snapshots(),
      builder: (context, snapshot) {
        final hasUnread = (snapshot.data?.docs ?? []).any((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final unreadBy = data['unreadBy'] as Map<String, dynamic>? ?? {};
          return (unreadBy[userId] ?? 0) > 0;
        });

        return _IconWithDot(
          icon: Icons.chat_bubble_outline_rounded,
          showDot: hasUnread,
          onTap: onTap,
        );
      },
    );
  }
}

class _IconWithDot extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final Color dotColor;
  final bool showDot;

  const _IconWithDot({
    required this.icon,
    this.onTap,
    this.color = AppColors.iconDefault,
    this.dotColor = AppColors.badgeSale,
    required this.showDot,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        _AppBarIcon(icon: icon, onTap: onTap, color: color),
        if (showDot)
          Positioned(
            top: 10,
            right: 9,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
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
