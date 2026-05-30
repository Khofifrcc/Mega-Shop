import '../../../core/services/api_service.dart';
import '../domain/entities/reel.dart';

class ReelRepository {
  final ApiService apiService = ApiService();

  Future<List<Reel>> getReels() async {
    final data = await apiService.get('/reels/');

    return (data as List).map((item) {
      return Reel(
        id: item['id'].toString(),
        username: item['username'] ?? '',
        userAvatar: item['user_avatar'] ?? '',
        productName: item['product_name'] ?? '',
        price: (item['price'] ?? 0).toDouble(),
        videoUrl: item['video_url'] ?? '',
        originalPrice: item['original_price'] == null
            ? null
            : (item['original_price'] as num).toDouble(),
        imageUrl: item['image_url'] ?? '',
        likeCount: item['like_count'] ?? 0,
        commentCount: item['comment_count'] ?? 0,
        isFollowing: item['is_following'] ?? false,
      );
    }).toList();
  }

  Future<void> createReel({
    required String username,
    required String userAvatar,
    required String productName,
    required double price,
    double? originalPrice,
    required String imageUrl,
    required String videoUrl,
    int likeCount = 0,
    int commentCount = 0,
    bool isFollowing = false,
  }) async {
    await apiService.post('/reels/', {
      'username': username,
      'user_avatar': userAvatar,
      'product_name': productName,
      'price': price,
      'original_price': originalPrice,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'like_count': likeCount,
      'comment_count': commentCount,
      'is_following': isFollowing,
    });
  }
}
