import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
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

  /// Opens/creates a seller conversation when arriving from product detail.

  Future<void> _openConversation(_Conversation conv) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance.collection('chats').doc(conv.id).set({
        'unreadBy': {userId: 0},
      }, SetOptions(merge: true));
    }

    if (!mounted) return;
    Navigator.pushNamed(context, '/conversation', arguments: conv);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

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
          // Conversations list
          Expanded(
            child: currentUserId == null
                ? Center(
                    child: Text(
                      'Please login first.',
                      style: AppTextStyles.brandName,
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .where(
                          'members',
                          arrayContains: currentUserId,
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
                          final userId =
                              FirebaseAuth.instance.currentUser?.uid ?? '';

                          final otherName = data['buyerId'] == userId
                              ? data['sellerName']
                              : data['buyerName'];

                          final otherAvatar = data['buyerId'] == userId
                              ? data['sellerAvatar']
                              : data['buyerAvatar'];

                          final unreadBy =
                              (data['unreadBy'] as Map<String, dynamic>?) ?? {};
                          final updatedAt = data['updatedAt'];

                          final conv = _Conversation(
                            id: docs[i].id,
                            name: otherName ?? 'User',
                            avatarUrl: otherAvatar ?? '',
                            lastMessage: data['lastMessage'] ?? '',
                            time: updatedAt is Timestamp
                                ? _formatTime(updatedAt)
                                : '',
                            unreadCount:
                                unreadBy[userId] ?? data['unreadCount'] ?? 0,
                            isTyping: data['isTyping'] ?? false,
                            isMegaShop: data['isMegaShop'] ?? false,
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

  String _formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    if (now.difference(date).inDays == 0) {
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    return '${date.day}/${date.month}';
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
                conv.lastMessage,
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
