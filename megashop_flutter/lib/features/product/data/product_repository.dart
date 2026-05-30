import '../../../core/services/api_service.dart';
import '../../home/domain/entities/product.dart';

class ProductRepository {
  final ApiService apiService = ApiService();

  Future<List<Product>> getProducts() async {
    final data = await apiService.get('/products/');

    return (data as List).map((item) {
      return Product(
        id: item['id'].toString(),
        name: item['name'],
        brand: item['seller_name'] ?? 'Mega Shop',
        price: (item['price'] as num).toDouble(),
        imageUrl: item['image'],
        badge: 'NEW',
      );
    }).toList();
  }

  Future<void> createProduct({
    required String name,
    required int price,
    required String description,
    required String image,
    required String sellerName,
  }) async {
    await apiService.post('/products/', {
      'name': name,
      'price': price,
      'description': description,
      'image': image,
      'seller_name': sellerName,
    });
  }
}
