import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Chat list / Messages page matching the mockup.
class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final _searchCtrl = TextEditingController();

  final _conversations = _mockConversations;

  @override
  void dispose() {
    _searchCtrl.dispose();
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
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
        ),
        title: Text('Messages',
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 20)),
        centerTitle: true,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.edit_rounded,
                    color: AppColors.textPrimary),
              ),
              Positioned(
                top: 10,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: AppColors.badgeSale, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search messages or creators...',
                hintStyle: AppTextStyles.brandName,
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.iconMuted, size: 20),
                filled: true,
                fillColor: AppColors.primarySurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          // Active stories row
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _StoryAvatar(
                    name: 'Your Story',
                    imageUrl:
                        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&q=80',
                    isOnline: true),
                const SizedBox(width: 12),
                _StoryAvatar(
                    name: 'Leo',
                    imageUrl:
                        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&q=80',
                    isOnline: true),
              ],
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),
          // Conversations list
          Expanded(
            child: ListView.separated(
              itemCount: _conversations.length,
              separatorBuilder: (ctx, i) =>
                  const Divider(color: AppColors.divider, height: 1),
              itemBuilder: (context, i) => _ConversationTile(
                conv: _conversations[i],
                onTap: () => Navigator.pushNamed(
                  context,
                  '/conversation',
                  arguments: _conversations[i],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  final String name;
  final String imageUrl;
  final bool isOnline;

  const _StoryAvatar(
      {required this.name, required this.imageUrl, this.isOnline = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 56,
              height: 56,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primaryLight, AppColors.primary],
                ),
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (ctx, url) =>
                      Container(color: AppColors.primarySurface),
                  errorWidget: (ctx, url, err) =>
                      Container(color: AppColors.primarySurface),
                ),
              ),
            ),
            if (isOnline)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(name, style: AppTextStyles.storyUsername),
      ],
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final _Conversation conv;
  final VoidCallback onTap;

  const _ConversationTile({required this.conv, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: conv.isMegaShop
          ? Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                  color: AppColors.accent, shape: BoxShape.circle),
              child: const Icon(Icons.shopping_bag_rounded,
                  color: AppColors.textOnPrimary, size: 26),
            )
          : ClipOval(
              child: CachedNetworkImage(
                imageUrl: conv.avatarUrl,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                placeholder: (ctx, url) =>
                    Container(color: AppColors.primarySurface),
                errorWidget: (ctx, url, err) =>
                    Container(color: AppColors.primarySurface),
              ),
            ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(conv.name, style: AppTextStyles.productName),
          Text(conv.time,
              style: conv.unreadCount > 0
                  ? AppTextStyles.brandName.copyWith(color: AppColors.primary)
                  : AppTextStyles.brandName),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                conv.lastMessage,
                style: conv.isTyping
                    ? AppTextStyles.brandName.copyWith(
                        color: AppColors.primary,
                        fontStyle: FontStyle.italic)
                    : AppTextStyles.brandName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (conv.unreadCount > 0)
              Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 22),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Text('${conv.unreadCount}',
                    style: AppTextStyles.badge.copyWith(fontSize: 10),
                    textAlign: TextAlign.center),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Mock data ─────────────────────────────────────────────────────────────────

class _Conversation {
  final String id;
  final String name;
  final String avatarUrl;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isTyping;
  final bool isMegaShop;

  const _Conversation({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
    this.isTyping = false,
    this.isMegaShop = false,
  });
}

final _mockConversations = [
  const _Conversation(
    id: 'c1',
    name: 'Aria Montgomery',
    avatarUrl:
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&q=80',
    lastMessage: 'Are those new sneakers still in stoc...',
    time: '2m ago',
    unreadCount: 2,
  ),
  const _Conversation(
    id: 'c2',
    name: 'Julian Rossi',
    avatarUrl:
        'https://images.unsplash.com/photo-1527980965255-d3b416303d12?w=100&q=80',
    lastMessage: 'Thanks! The jacket fits perfectly. 🔥',
    time: '1h ago',
  ),
  const _Conversation(
    id: 'c3',
    name: 'Elena Vance',
    avatarUrl:
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&q=80',
    lastMessage: 'Elena is typing...',
    time: 'Yesterday',
    isTyping: true,
  ),
  const _Conversation(
    id: 'c4',
    name: 'MegaShop Orders',
    avatarUrl: '',
    lastMessage: 'Your order #MS-0922 has shipped!',
    time: 'Mon',
    isMegaShop: true,
  ),
];
