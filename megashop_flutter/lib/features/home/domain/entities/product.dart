/// Domain entity representing a product shown on the Home screen.
/// Pure Dart — no Flutter dependencies; suitable for unit testing.
class Product {
  final String id;
  final String name;
  final String brand;

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
    required this.name,
    required this.brand,
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
