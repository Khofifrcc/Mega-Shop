class PostModel {
  final int id;
  final String userId;
  final String caption;
  final String image;

  PostModel({
    required this.id,
    required this.userId,
    required this.caption,
    required this.image,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'],
      userId: json['user_id'],
      caption: json['caption'],
      image: json['image'],
    );
  }
}
