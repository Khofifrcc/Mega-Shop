import '../../../core/services/api_service.dart';
import '../../../shared/models/post_model.dart';

class PostRepository {
  final ApiService apiService = ApiService();

  Future<List<PostModel>> getPosts() async {
    final data = await apiService.get('/posts/');
    return (data as List).map((item) => PostModel.fromJson(item)).toList();
  }

  Future<void> createPost({
    required String userId,
    required String userName,
    required String caption,
    required String image,
    required String postType,
  }) async {
    await apiService.post('/posts/', {
      'user_id': userId,
      'user_name': userName,
      'caption': caption,
      'image': image,
      'post_type': postType,
    });
  }
}
