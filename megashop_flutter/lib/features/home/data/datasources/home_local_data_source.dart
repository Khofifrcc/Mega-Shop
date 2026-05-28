import '../../domain/entities/product.dart';
import '../../domain/entities/story.dart';

/// Local mock data source for the Home feature.
///
/// In a production app this would implement a repository interface and fetch
/// data from a remote API or local database.  For now it exposes static
/// lists that match the UI mockup exactly.
class HomeLocalDataSource {
  /// Returns the trending products shown in the 2-column grid.
  List<Product> getTrendingProducts() {
    return const [
      Product(
        id: 'p1',
        name: 'Minimalist Chrono Smart Watch Pro',
        brand: 'TechHaven',
        price: 149.99,
        imageUrl:
            'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400&q=80',
        badge: null,
        isFavorite: false,
      ),
      Product(
        id: 'p2',
        name: 'Velocity Max Running Sneakers',
        brand: 'Kicks & Co',
        price: 125.00,
        imageUrl:
            'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400&q=80',
        badge: 'NEW',
        isFavorite: false,
      ),
      Product(
        id: 'p3',
        name: 'Classic White Leather Low-Tops',
        brand: 'Boutique 9',
        price: 89.00,
        imageUrl:
            'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=400&q=80',
        badge: null,
        isFavorite: false,
      ),
      Product(
        id: 'p4',
        name: 'Matte Ceramic Minimal Vase',
        brand: 'Home Essentials',
        price: 45.00,
        originalPrice: 60.00,
        imageUrl:
            'https://images.unsplash.com/photo-1612196808214-b40139d0b175?w=400&q=80',
        badge: 'SALE',
        isFavorite: false,
      ),
    ];
  }

  /// Returns the stories list — first item is always the user's own story.
  List<Story> getStories() {
    return const [
      Story(
        id: 's0',
        username: 'Your Story',
        imageUrl: null,
        isOwnStory: true,
      ),
      Story(
        id: 's1',
        username: '@diana_v',
        imageUrl:
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&q=80',
      ),
      Story(
        id: 's2',
        username: '@marcus.t',
        imageUrl:
            'https://images.unsplash.com/photo-1527980965255-d3b416303d12?w=150&q=80',
      ),
      Story(
        id: 's3',
        username: '@chloe_sty...',
        imageUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&q=80',
      ),
      Story(
        id: 's4',
        username: '@alex_m',
        imageUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&q=80',
      ),
    ];
  }

  /// Returns the category filter labels.
  List<String> getCategories() {
    return ['All', 'Fashion', 'Tech', 'Home', 'Beauty'];
  }
}
