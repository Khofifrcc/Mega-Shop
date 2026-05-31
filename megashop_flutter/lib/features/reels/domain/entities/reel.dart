/// Domain entity for a Reel video item.
class Reel {
  final String id;
  final String username;
  final String userAvatar;
  final String caption;
  final String productName;
  final double price;
  final double? originalPrice;
  final String imageUrl;
  final String videoUrl;
  final int likeCount;
  final int commentCount;
  final bool isFollowing;
  final String userId;

  const Reel({
    required this.id,
    required this.username,
    required this.userAvatar,
    this.caption = '',
    required this.productName,
    required this.price,
    this.originalPrice,
    required this.imageUrl,
    required this.videoUrl,
    required this.likeCount,
    required this.commentCount,
    this.isFollowing = false,
    this.userId = '',
  });

  bool get isOnSale => originalPrice != null;
}
