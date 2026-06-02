import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Conversation / chat detail page matching the mockup.
///
/// Shows chat bubbles (sent = right/purple, received = left/lavender),
/// a product card embed inside a message, and a message input bar.
class ConversationPage extends StatefulWidget {
  const ConversationPage({super.key});

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String chatId) async {
    final text = _msgCtrl.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    if (text.isEmpty || user == null) return;

    _msgCtrl.clear();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': user.uid,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    String chatId = 'default';
    debugPrint('CHAT OPENED: $chatId');
    String name = 'MegaShop User';
    String avatar =
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&q=80';
    if (args is Map) {
      chatId = args['id']?.toString() ?? 'default';
      name = args['name']?.toString() ?? 'MegaShop User';
      avatar = args['avatar']?.toString() ??
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&q=80';

      debugPrint('CHAT OPENED: $chatId');
    } else if (args != null) {
      final dynamic dynamicArgs = args;
      chatId = dynamicArgs.id as String;
      name = dynamicArgs.name as String;
      avatar = dynamicArgs.avatarUrl as String;

      debugPrint('CHAT OPENED: $chatId');
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leadingWidth: 40,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          padding: EdgeInsets.zero,
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: CachedNetworkImageProvider(avatar),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTextStyles.productName.copyWith(fontSize: 15)),
                Text('Online',
                    style: AppTextStyles.brandName.copyWith(fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet. Say hi!',
                      style: AppTextStyles.brandName,
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;

                    final message = _ChatMessage(
                      id: docs[i].id,
                      isMe: data['senderId'] == currentUserId,
                      text: data['text'] ?? '',
                      time: '',
                      type: data['type'] ?? 'text',
                      productId: data['productId'] ?? '',
                      productName: data['productName'] ?? '',
                      productPrice: (data['productPrice'] ?? 0).toDouble(),
                      productImage: data['productImage'] ?? '',
                    );

                    return _BubbleItem(message: message);
                  },
                );
              },
            ),
          ),

          // Input bar
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                const Icon(Icons.add_circle_outline_rounded,
                    color: AppColors.iconMuted, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: InputDecoration(
                      hintText: 'Message $name...',
                      hintStyle: AppTextStyles.brandName,
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _send(chatId),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _send(chatId),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: AppColors.textOnPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String id;
  final bool isMe;
  final String text;
  final String time;
  final String type;
  final String productId;
  final String productName;
  final double productPrice;
  final String productImage;

  const _ChatMessage({
    required this.id,
    required this.isMe,
    required this.text,
    required this.time,
    this.type = 'text',
    this.productId = '',
    this.productName = '',
    this.productPrice = 0,
    this.productImage = '',
  });
}

class _BubbleItem extends StatelessWidget {
  final _ChatMessage message;

  const _BubbleItem({required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72),
          decoration: BoxDecoration(
            color: message.isMe ? AppColors.primary : AppColors.primarySurface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(message.isMe ? 16 : 4),
              bottomRight: Radius.circular(message.isMe ? 4 : 16),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.type == 'product') ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: message.productImage,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          placeholder: (ctx, url) =>
                              Container(color: AppColors.primarySurface),
                          errorWidget: (ctx, url, err) =>
                              Container(color: AppColors.primarySurface),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.productName,
                              style: AppTextStyles.productName
                                  .copyWith(fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${message.productPrice.toStringAsFixed(2)}',
                              style: AppTextStyles.price.copyWith(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Text(
                message.text,
                style: AppTextStyles.brandName.copyWith(
                  color: message.isMe
                      ? AppColors.textOnPrimary
                      : AppColors.textPrimary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
