class Product {
  final String id;
  final String name;
  final String brand;
  final double price;
  final double? originalPrice;
  final String imageUrl;
  final String? badge;
  final bool isFavorite;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    this.originalPrice,
    required this.imageUrl,
    this.badge,
    this.isFavorite = false,
  });

  bool get isOnSale => originalPrice != null;

  Product copyWith({
    String? id,
    String? name,
    String? brand,
    double? price,
    double? originalPrice,
    String? imageUrl,
    String? badge,
    bool? isFavorite,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      badge: badge ?? this.badge,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
