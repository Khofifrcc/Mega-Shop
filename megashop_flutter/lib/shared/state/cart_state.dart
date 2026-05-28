import 'package:flutter/material.dart';

/// Shared cart state passed between pages via constructor / InheritedWidget-lite.
/// In production this would be replaced by Riverpod or BLoC.
class CartState extends ChangeNotifier {
  final List<CartEntry> _items = [
    CartEntry(
      id: 'c1',
      productId: 'p_shoe',
      name: 'Aero Glide Pro 3',
      variant: 'Size 10 • Crimson Red',
      price: 145.00,
      quantity: 1,
      imageUrl:
          'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=300&q=80',
    ),
    CartEntry(
      id: 'c2',
      productId: 'p_watch',
      name: 'Tempo Smartwatch...',
      variant: '42mm • Frost White',
      price: 299.00,
      quantity: 1,
      imageUrl:
          'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=300&q=80',
    ),
  ];

  List<CartEntry> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, e) => sum + e.quantity);

  double get subtotal => _items.fold(0, (sum, e) => sum + e.price * e.quantity);
  double get tax => subtotal * 0.08;
  double get total => subtotal + tax;

  void increment(String id) {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(quantity: _items[idx].quantity + 1);
      notifyListeners();
    }
  }

  void decrement(String id) {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx >= 0 && _items[idx].quantity > 1) {
      _items[idx] = _items[idx].copyWith(quantity: _items[idx].quantity - 1);
      notifyListeners();
    }
  }

  void remove(String id) {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void addItem({
    required String productId,
    required String name,
    required String variant,
    required double price,
    required String imageUrl,
  }) {
    final existing = _items.indexWhere((e) => e.productId == productId);
    if (existing >= 0) {
      _items[existing] = _items[existing]
          .copyWith(quantity: _items[existing].quantity + 1);
    } else {
      _items.add(CartEntry(
        id: 'c_${DateTime.now().millisecondsSinceEpoch}',
        productId: productId,
        name: name,
        variant: variant,
        price: price,
        quantity: 1,
        imageUrl: imageUrl,
      ));
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

class CartEntry {
  final String id;
  final String productId;
  final String name;
  final String variant;
  final double price;
  final int quantity;
  final String imageUrl;

  const CartEntry({
    required this.id,
    required this.productId,
    required this.name,
    required this.variant,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });

  CartEntry copyWith({int? quantity}) => CartEntry(
        id: id,
        productId: productId,
        name: name,
        variant: variant,
        price: price,
        quantity: quantity ?? this.quantity,
        imageUrl: imageUrl,
      );
}

/// InheritedWidget wrapper so any descendant can call CartState.of(context)
class CartStateProvider extends InheritedNotifier<CartState> {
  const CartStateProvider({
    super.key,
    required CartState cart,
    required super.child,
  }) : super(notifier: cart);

  static CartState of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<CartStateProvider>();
    assert(provider != null, 'CartStateProvider not found in widget tree');
    return provider!.notifier!;
  }
}
