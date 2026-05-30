import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class UploadService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  Future<String> uploadVideo(XFile video) async {
    final uri = Uri.parse('$baseUrl/reels/upload-video/');
    final request = http.MultipartRequest('POST', uri);

    final bytes = await video.readAsBytes();

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: video.name,
      ),
    );

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(body);
      return data['video_url'];
    }

    throw Exception('Failed to upload video: $body');
  }

  Future<String> uploadImage(XFile imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/upload/image'),
    );

    final bytes = await imageFile.readAsBytes();

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: imageFile.name,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('UPLOAD STATUS: ${response.statusCode}');
    print('UPLOAD BODY: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['image_url'];
    }

    throw Exception('Failed to upload image');
  }
}
