/// Domain entity representing a product shown on the Home screen.
/// Pure Dart — no Flutter dependencies; suitable for unit testing.
class Product {
  final String id;
  final String ownerId;
  final String name;
  final String brand;
  final String description;

  /// Current selling price in USD
  final double price;

  /// Original price before discount; null if no sale
  final double? originalPrice;

  /// URL to the product's hero image
  final String imageUrl;

  /// Optional badge label: 'NEW', 'SALE', or null
  final String? badge;

  /// Whether this item is in the user's wishlist
  final bool isFavorite;

  const Product({
    required this.id,
    this.ownerId = '',
    required this.name,
    required this.brand,
    this.description = '',
    required this.price,
    this.originalPrice,
    required this.imageUrl,
    this.badge,
    this.isFavorite = false,
  });

  /// Returns true when the product has a strikethrough original price
  bool get isOnSale => originalPrice != null;

  Product copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? brand,
    String? description,
    double? price,
    double? originalPrice,
    String? imageUrl,
    String? badge,
    bool? isFavorite,
  }) {
    return Product(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      badge: badge ?? this.badge,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
