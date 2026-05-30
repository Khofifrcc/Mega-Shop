class ProductModel {
  final int id;
  final String name;
  final int price;
  final String description;
  final String image;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.image,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      description: json['description'],
      image: json['image'],
    );
  }
}
