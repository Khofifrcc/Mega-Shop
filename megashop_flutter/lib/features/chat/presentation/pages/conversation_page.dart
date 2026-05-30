import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/state/chat_state.dart';

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

  late final List<_ChatMessage> _staticMessages;
  final List<_ChatMessage> _dynamicMessages = [];

  @override
  void initState() {
    super.initState();
    _staticMessages = [
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
    ChatService.instance.addListener(_onChatServiceChanged);
  }

  void _onChatServiceChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ChatService.instance.removeListener(_onChatServiceChanged);
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _dynamicMessages.add(_ChatMessage(
        id: 'm_dyn_${DateTime.now().millisecondsSinceEpoch}',
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
    final args = ModalRoute.of(context)?.settings.arguments;
    String name = 'MegaShop Luxe';
    String avatar = 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&q=80';
    String id = 'default';

    if (args != null) {
      try {
        final dynamic dynamicArgs = args;
        id = dynamicArgs.id as String;
        name = dynamicArgs.name as String;
        avatar = dynamicArgs.avatarUrl as String;
      } catch (_) {
        if (args is Map) {
          id = args['id'] ?? 'default';
          name = args['name'] ?? 'MegaShop Luxe';
          avatar = args['avatar'] ?? 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&q=80';
        }
      }
    }

    final extraMsgs = ChatService.instance.extraMessages[id] ?? [];
    final allMessages = [
      ..._staticMessages,
      ...extraMsgs.map((m) => _ChatMessage(
            id: m['id'] as String,
            isMe: m['isMe'] as bool,
            text: m['text'] as String,
            time: m['time'] as String,
            hasProductCard: m['hasProductCard'] as bool? ?? false,
            productName: m['productName'] as String?,
            productPrice: m['productPrice'] as String?,
            productImage: m['productImage'] as String?,
          )),
      ..._dynamicMessages,
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leadingWidth: 40,
        leading: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.primary),
            padding: EdgeInsets.zero,
          ),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: CachedNetworkImageProvider(avatar),
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
                Text(name,
                    style:
                        AppTextStyles.productName.copyWith(fontSize: 15)),
                Text('Typically replies in 5m',
                    style: AppTextStyles.brandName.copyWith(fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: allMessages.length,
              itemBuilder: (context, i) =>
                  _BubbleItem(message: allMessages[i]),
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
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {},
                    child: const Icon(Icons.add_circle_outline_rounded,
                        color: AppColors.iconMuted, size: 26),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: InputDecoration(
                      hintText: 'Message $name...',
                      hintStyle: AppTextStyles.brandName,
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
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
