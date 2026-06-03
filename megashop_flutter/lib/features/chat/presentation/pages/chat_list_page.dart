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

  void _showNewChatSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewChatBottomSheet(
        onUserSelected: (userMap) async {
          Navigator.pop(context); // close sheet
          await _startNewChat(userMap);
        },
      ),
    );
  }

  Future<void> _startNewChat(Map<String, dynamic> selectedUser) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final selectedUserId = selectedUser['uid'] as String?;
    if (selectedUserId == null) return;

    // 1. Check if chat already exists
    final snapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('members', arrayContains: currentUserId)
        .get();

    QueryDocumentSnapshot? existingChat;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final members = List<String>.from(data['members'] ?? []);
      if (members.contains(selectedUserId)) {
        existingChat = doc;
        break;
      }
    }

    if (existingChat != null) {
      // Open existing chat
      final data = existingChat.data() as Map<String, dynamic>;
      final otherName = data['buyerId'] == currentUserId
          ? data['sellerName']
          : data['buyerName'];

      final otherAvatar = data['buyerId'] == currentUserId
          ? data['sellerAvatar']
          : data['buyerAvatar'];

      final unreadBy = (data['unreadBy'] as Map<String, dynamic>?) ?? {};
      final updatedAt = data['updatedAt'];

      final conv = _Conversation(
        id: existingChat.id,
        name: otherName ?? 'User',
        avatarUrl: otherAvatar ?? '',
        lastMessage: data['lastMessage'] ?? '',
        time: updatedAt is Timestamp ? _formatTime(updatedAt) : '',
        unreadCount: unreadBy[currentUserId] ?? data['unreadCount'] ?? 0,
        isTyping: data['isTyping'] ?? false,
        isMegaShop: data['isMegaShop'] ?? false,
      );
      _openConversation(conv);
      return;
    }

    // 2. Create new chat
    final currentUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();
    final currentUserData = currentUserDoc.data() ?? {};

    final docRef = await FirebaseFirestore.instance.collection('chats').add({
      'members': [currentUserId, selectedUserId],
      'buyerId': currentUserId,
      'buyerName': currentUserData['username'] ?? 'Me',
      'buyerAvatar': currentUserData['profilePhoto'] ?? '',
      'sellerId': selectedUserId,
      'sellerName': selectedUser['username'] ?? 'User',
      'sellerAvatar': selectedUser['profilePhoto'] ?? '',
      'lastMessage': '',
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadCount': 0,
      'unreadBy': {},
      'isTyping': false,
      'isMegaShop': false,
    });

    final conv = _Conversation(
      id: docRef.id,
      name: selectedUser['username'] ?? 'User',
      avatarUrl: selectedUser['profilePhoto'] ?? '',
      lastMessage: '',
      time: '',
      unreadCount: 0,
    );
    _openConversation(conv);
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
                onPressed: _showNewChatSheet,
                icon: const Icon(Icons.add_comment_rounded,
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(conv.time,
                  style: conv.unreadCount > 0
                      ? AppTextStyles.brandName.copyWith(color: AppColors.primary)
                      : AppTextStyles.brandName),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: AppColors.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (ctx) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 8, bottom: 8),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.divider,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.delete_outline_rounded, color: AppColors.badgeSale),
                            title: Text('Delete Conversation', style: AppTextStyles.productName.copyWith(color: AppColors.badgeSale)),
                            onTap: () async {
                              Navigator.pop(ctx);
                              await FirebaseFirestore.instance.collection('chats').doc(conv.id).delete();
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  );
                },
                child: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.iconMuted),
              ),
            ],
          ),
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

// ── New Chat Bottom Sheet ───────────────────────────────────────────────────

class _NewChatBottomSheet extends StatefulWidget {
  final Function(Map<String, dynamic> user) onUserSelected;

  const _NewChatBottomSheet({required this.onUserSelected});

  @override
  State<_NewChatBottomSheet> createState() => _NewChatBottomSheetState();
}

class _NewChatBottomSheetState extends State<_NewChatBottomSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text('New Message', style: AppTextStyles.sectionTitle.copyWith(fontSize: 18)),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: AppTextStyles.brandName,
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.iconMuted, size: 20),
                filled: true,
                fillColor: AppColors.primarySurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading users', style: AppTextStyles.brandName));
                }

                final docs = snapshot.data?.docs ?? [];
                final filteredDocs = docs.where((doc) {
                  if (doc.id == currentUserId) return false;
                  final data = doc.data() as Map<String, dynamic>;
                  final username = (data['username'] ?? '').toString().toLowerCase();
                  return username.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(child: Text('No users found.', style: AppTextStyles.brandName));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
                    data['uid'] = doc.id; // Guarantee uid is present
                    
                    final avatarUrl = data['profilePhoto'] ?? '';
                    final username = data['username'] ?? 'User';

                    return ListTile(
                      onTap: () => widget.onUserSelected(data),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primarySurface,
                        backgroundImage: avatarUrl.toString().isNotEmpty
                            ? CachedNetworkImageProvider(avatarUrl)
                            : null,
                        child: avatarUrl.toString().isEmpty
                            ? Text(
                                username.isNotEmpty ? username[0].toUpperCase() : '?',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      title: Text(username, style: AppTextStyles.productName),
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
