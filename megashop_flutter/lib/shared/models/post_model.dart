class PostModel {
  final int id;
  final String userId;
  final String caption;
  final String image;
  final String postType;
  int likes;
  bool isLiked;

  PostModel({
    required this.id,
    required this.userId,
    required this.caption,
    required this.image,
    required this.postType,
    required this.likes,
    this.isLiked = false,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'],
      userId: json['user_id'],
      caption: json['caption'],
      image: json['image'],
      postType: json['post_type'] ?? 'regular',
      likes: json['likes'] ?? 0,
    );
  }
}
