import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadImage(XFile imageFile) async {
    final file = File(imageFile.path);

    final fileName = DateTime.now().millisecondsSinceEpoch.toString();

    final ref = _storage.ref().child('products/$fileName.jpg');

    await ref.putFile(file);

    final downloadUrl = await ref.getDownloadURL();

    return downloadUrl;
  }
}
