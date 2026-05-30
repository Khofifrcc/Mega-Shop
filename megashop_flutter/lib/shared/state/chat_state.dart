import 'package:flutter/material.dart';

/// Lightweight singleton to store and sync messages shared from Reels.
class ChatService extends ChangeNotifier {
  static final ChatService instance = ChatService._internal();

  ChatService._internal();

  /// Maps conversation ID to lists of dynamically added messages.
  final Map<String, List<Map<String, dynamic>>> extraMessages = {};

  /// Exposes a list of dynamic mock friends we can send Reels to.
  final List<ChatFriend> friends = [
    const ChatFriend(
      id: 'c1',
      name: 'Aria Montgomery',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&q=80',
    ),
    const ChatFriend(
      id: 'c2',
      name: 'Julian Rossi',
      avatarUrl: 'https://images.unsplash.com/photo-1527980965255-d3b416303d12?w=100&q=80',
    ),
    const ChatFriend(
      id: 'c3',
      name: 'Elena Vance',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&q=80',
    ),
    const ChatFriend(
      id: 'c4',
      name: 'Marcus Thorne',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&q=80',
    ),
    const ChatFriend(
      id: 'c5',
      name: 'Diana Prince',
      avatarUrl: 'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?w=100&q=80',
    ),
  ];

  /// Send a Reel to a specific conversation/friend
  void sendReel({
    required String conversationId,
    required String reelId,
    required String productName,
    required double productPrice,
    required String productImage,
    required String videoUrl,
  }) {
    extraMessages.putIfAbsent(conversationId, () => []).add({
      'id': 'shared_reel_${DateTime.now().millisecondsSinceEpoch}',
      'isMe': true,
      'text': 'Shared a reel video: $productName',
      'time': 'Now',
      'hasProductCard': true,
      'productName': productName,
      'productPrice': '\$${productPrice.toStringAsFixed(2)}',
      'productImage': productImage,
    });
    notifyListeners();
  }
}

class ChatFriend {
  final String id;
  final String name;
  final String avatarUrl;

  const ChatFriend({
    required this.id,
    required this.name,
    required this.avatarUrl,
  });
}
