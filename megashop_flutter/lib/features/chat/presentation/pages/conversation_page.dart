import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

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

  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      id: 'm1',
      isMe: false,
      text:
          'Hi there! 👋 Welcome to MegaShop Luxe. How can I assist you with your wardrobe today?',
      time: 'TODAY, 10:42 AM',
      isDateDivider: true,
    ),
    const _ChatMessage(
      id: 'm2',
      isMe: true,
      text:
          'I\'m looking at the "Aero Glide Sneakers" in size 10. Are they true to size, or should I size up?',
      time: '10:44 AM',
    ),
    const _ChatMessage(
      id: 'm3',
      isMe: false,
      text:
          'Great choice! The Aero Glides run perfectly true to size for a snug, athletic fit.',
      time: '10:46 AM',
      hasProductCard: true,
      productName: 'Aero Glide Sneaker',
      productPrice: '\$145.00',
      productImage:
          'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=200&q=80',
      followUpText:
          'If you prefer a roomier feel or wear thick socks, going up a half size is a good idea. Would you like me to check stock for size 10.5 as well?',
    ),
  ];

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(
        id: 'm${_messages.length + 1}',
        isMe: true,
        text: text,
        time: TimeOfDay.now().format(context),
      ));
      _msgCtrl.clear();
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leadingWidth: 40,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.primary),
          padding: EdgeInsets.zero,
        ),
        title: Row(
          children: [
            Stack(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(
                      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&q=80'),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.background, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MegaShop Luxe',
                    style:
                        AppTextStyles.productName.copyWith(fontSize: 15)),
                Text('Typically replies in 5m',
                    style: AppTextStyles.brandName.copyWith(fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded,
                color: AppColors.textPrimary),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, i) =>
                  _BubbleItem(message: _messages[i]),
            ),
          ),
          // Input bar
          Container(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {},
                  child: const Icon(Icons.add_circle_outline_rounded,
                      color: AppColors.iconMuted, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: InputDecoration(
                      hintText: 'Message MegaShop...',
                      hintStyle: AppTextStyles.brandName,
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: AppColors.textOnPrimary, size: 20),
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
  final bool isDateDivider;
  final bool hasProductCard;
  final String? productName;
  final String? productPrice;
  final String? productImage;
  final String? followUpText;

  const _ChatMessage({
    required this.id,
    required this.isMe,
    required this.text,
    required this.time,
    this.isDateDivider = false,
    this.hasProductCard = false,
    this.productName,
    this.productPrice,
    this.productImage,
    this.followUpText,
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
        if (message.isDateDivider) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(message.time,
                style: AppTextStyles.brandName
                    .copyWith(fontSize: 11, color: AppColors.iconMuted)),
          ),
          const SizedBox(height: 8),
        ],
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
              if (message.hasProductCard) ...[
                const SizedBox(height: 10),
                Container(
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
                          imageUrl: message.productImage!,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          placeholder: (ctx, url) =>
                              Container(color: AppColors.primarySurface),
                          errorWidget: (ctx, url, err) =>
                              Container(color: AppColors.primarySurface),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(message.productName!,
                              style: AppTextStyles.productName
                                  .copyWith(fontSize: 13)),
                          Text(message.productPrice!,
                              style: AppTextStyles.price
                                  .copyWith(fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (message.followUpText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    message.followUpText!,
                    style: AppTextStyles.brandName.copyWith(
                        fontSize: 13, height: 1.5),
                  ),
                ],
              ],
            ],
          ),
        ),
        if (!message.isDateDivider)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(message.time,
                style: AppTextStyles.brandName.copyWith(fontSize: 10)),
          ),
      ],
    );
  }
}
