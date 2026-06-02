import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/state/chat_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Chat list / Messages page matching the mockup.
class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  void _onChatServiceChanged() {
    if (mounted) setState(() {});
  }

  /// Opens/creates a seller conversation when arriving from product detail.

  void _openConversation(_Conversation conv) {
    Navigator.pushNamed(context, '/conversation', arguments: conv);
  }

  @override
  void dispose() {
    ChatService.instance.removeListener(_onChatServiceChanged);
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
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where(
                    'members',
                    arrayContains: FirebaseAuth.instance.currentUser?.uid,
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Chat error: ${snapshot.error}',
                      style: AppTextStyles.brandName,
                    ),
                  );
                }
                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet.',
                      style: AppTextStyles.brandName,
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (ctx, i) =>
                      const Divider(color: AppColors.divider, height: 1),
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

                    final otherName = data['buyerId'] == userId
                        ? data['sellerName']
                        : data['buyerName'];

                    final otherAvatar = data['buyerId'] == userId
                        ? data['sellerAvatar']
                        : data['buyerAvatar'];

                    final conv = _Conversation(
                      id: docs[i].id,
                      name: otherName ?? 'User',
                      avatarUrl: otherAvatar ?? '',
                      lastMessage: data['lastMessage'] ?? '',
                      time: 'Now',
                    );

                    return _ConversationTile(
                      conv: conv,
                      onTap: () => _openConversation(conv),
                    );
                  },
                );
              },
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                (ChatService.instance.extraMessages[conv.id]?.isNotEmpty ??
                        false)
                    ? ChatService.instance.extraMessages[conv.id]!.last['text']
                        as String
                    : conv.lastMessage,
                style: conv.isTyping
                    ? AppTextStyles.brandName.copyWith(
                        color: AppColors.primary, fontStyle: FontStyle.italic)
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
