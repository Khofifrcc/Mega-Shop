import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/product.dart';

Product productFromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>? ?? {};

  return Product(
    id: doc.id,
    description: data['description'] ?? '',
    ownerId: data['ownerId'] ?? '',
    ownerAvatar: data['ownerAvatar'] ??
        data['sellerAvatar'] ??
        data['profileImageUrl'] ??
        '',
    name: data['name'] ?? '',
    brand: data['ownerUsername'] ?? data['ownerEmail'] ?? 'Seller',
    category: data['category'] ?? 'Fashion',
    price: (data['price'] ?? 0).toDouble(),
    originalPrice: (data['originalPrice'] as num?)?.toDouble(),
    imageUrl: data['imageUrl'] ?? '',
    imageUrls: data['imageUrls'] != null ? List<String>.from(data['imageUrls']) : [(data['imageUrl'] ?? '')],
    badge: data['mediaType'] == 'Photo' ? 'NEW' : data['badge'],
    isFavorite: data['isFavorite'] ?? false,
  );
}
