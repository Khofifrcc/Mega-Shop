import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Shared cart state passed between pages via constructor / InheritedWidget-lite.
/// In production this would be replaced by Riverpod or BLoC.
class CartState extends ChangeNotifier {
  final List<CartEntry> _items = [];

  List<CartEntry> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, e) => sum + e.quantity);

  double get subtotal => _items.fold(0, (sum, e) => sum + e.price * e.quantity);
  double get tax => subtotal * 0.08;
  double get total => subtotal + tax;

  // ── Increment cart item quantity in Firestore ─────────────────────────────
  Future<void> increment(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseFirestore.instance
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .doc(id);

    await ref.update({
      'quantity': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Decrement cart item quantity in Firestore ─────────────────────────────
  //
  // If quantity becomes 0, the item is removed from cart.
  //
  Future<void> decrement(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseFirestore.instance
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .doc(id);

    final doc = await ref.get();
    final qty = doc.data()?['quantity'] ?? 1;

    if (qty > 1) {
      await ref.update({
        'quantity': qty - 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.delete();
    }
  }

  // ── Remove single item from Firestore cart ────────────────────────────────
  Future<void> remove(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .doc(id)
        .delete();
  }

  // ── Clear all cart items for current user ─────────────────────────────────
  Future<void> clear() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final items = await FirebaseFirestore.instance
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .get();

    for (final doc in items.docs) {
      await doc.reference.delete();
    }
  }

  // ── Add product to Firestore cart ─────────────────────────────────────────
  //
  // Cart is stored per user:
  //
  // carts
  //   userId
  //     items
  //       productId
  //
  // If the item already exists, only quantity is increased.
  //
  Future<void> addItem({
    required String productId,
    required String name,
    required String variant,
    required double price,
    required String imageUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cartRef = FirebaseFirestore.instance
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .doc(productId);

    final doc = await cartRef.get();

    if (doc.exists) {
      final currentQty = doc.data()?['quantity'] ?? 1;

      await cartRef.update({
        'quantity': currentQty + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await cartRef.set({
        'productId': productId,
        'name': name,
        'variant': variant,
        'price': price,
        'imageUrl': imageUrl,
        'quantity': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

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
