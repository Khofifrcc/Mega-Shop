import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/state/cart_state.dart';
import '../../../../shared/widgets/mega_bottom_nav.dart';

/// Cart page matching the mockup.
///
/// Shows list of cart items with qty controls, promo code input,
/// order summary, and a sticky "Checkout →" amber button.
/// Bottom nav is preserved so the user is never stranded.
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _promoCtrl = TextEditingController();
  bool _promoApplied = false;

  @override
  void dispose() {
    _promoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartStateProvider.of(context);
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.primary),
            ),
            title: Text('Cart',
                style: AppTextStyles.sectionTitle
                    .copyWith(color: AppColors.primary)),
            centerTitle: true,
            actions: [
              if (cart.items.isNotEmpty)
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        title: Text('Clear Cart',
                            style: AppTextStyles.sectionTitle
                                .copyWith(fontSize: 18)),
                        content: Text(
                            'Remove all items from cart?',
                            style: AppTextStyles.brandName),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel',
                                  style: AppTextStyles.brandName
                                      .copyWith(color: AppColors.iconMuted))),
                          TextButton(
                              onPressed: () {
                                cart.clear();
                                Navigator.pop(context);
                              },
                              child: Text('Clear',
                                  style: AppTextStyles.brandName.copyWith(
                                      color: AppColors.badgeSale))),
                        ],
                      ),
                    );
                  },
                  child: Text('Clear',
                      style: AppTextStyles.brandName
                          .copyWith(color: AppColors.badgeSale, fontSize: 13)),
                ),
              const SizedBox(width: 4),
            ],
          ),
          body: cart.items.isEmpty
              ? _EmptyCart(
                  onShop: () => Navigator.pushReplacementNamed(context, '/home'))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          children: [
                            // Items
                            ...cart.items.map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _CartItemCard(
                                    item: item,
                                    onIncrement: () =>
                                        cart.increment(item.id),
                                    onDecrement: () =>
                                        cart.decrement(item.id),
                                    onRemove: () => cart.remove(item.id),
                                  ),
                                )),
                            const SizedBox(height: 8),
                            // Promo
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: _promoApplied
                                    ? AppColors.primarySurface
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _promoApplied
                                      ? AppColors.primary
                                      : AppColors.divider,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.local_offer_outlined,
                                    color: _promoApplied
                                        ? AppColors.primary
                                        : AppColors.iconMuted,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _promoCtrl,
                                      decoration: InputDecoration(
                                        hintText: _promoApplied
                                            ? 'MEGA10 applied ✓'
                                            : 'Enter promo code',
                                        hintStyle: AppTextStyles.brandName
                                            .copyWith(
                                          color: _promoApplied
                                              ? AppColors.primary
                                              : null,
                                        ),
                                        border: InputBorder.none,
                                      ),
                                      style: AppTextStyles.productName
                                          .copyWith(fontSize: 14),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      if (_promoCtrl.text.isNotEmpty) {
                                        setState(
                                            () => _promoApplied = true);
                                      }
                                    },
                                    child: Text('Apply',
                                        style:
                                            AppTextStyles.buttonOutlined),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Order summary
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                      color: AppColors.shadow,
                                      blurRadius: 8,
                                      offset: Offset(0, 2))
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('Order Summary',
                                      style: AppTextStyles.sectionTitle
                                          .copyWith(fontSize: 18)),
                                  const SizedBox(height: 16),
                                  _SummaryRow(
                                      label:
                                          'Subtotal (${cart.items.length} items)',
                                      value:
                                          '\$${cart.subtotal.toStringAsFixed(2)}'),
                                  const SizedBox(height: 10),
                                  _SummaryRow(
                                      label: 'Shipping',
                                      value: 'Free',
                                      valueColor: AppColors.primary),
                                  const SizedBox(height: 10),
                                  _SummaryRow(
                                      label: 'Tax (8%)',
                                      value:
                                          '\$${cart.tax.toStringAsFixed(2)}'),
                                  if (_promoApplied) ...[
                                    const SizedBox(height: 10),
                                    _SummaryRow(
                                        label: 'Promo (MEGA10)',
                                        value:
                                            '-\$${(cart.subtotal * 0.10).toStringAsFixed(2)}',
                                        valueColor: AppColors.primary),
                                  ],
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 12),
                                    child:
                                        Divider(color: AppColors.divider),
                                  ),
                                  _SummaryRow(
                                    label: 'Total',
                                    value:
                                        '\$${cart.total.toStringAsFixed(2)}',
                                    labelStyle:
                                        AppTextStyles.sectionTitle
                                            .copyWith(fontSize: 17),
                                    valueStyle: AppTextStyles.price
                                        .copyWith(
                                            fontSize: 22,
                                            color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Checkout button — sits ABOVE bottom nav, never overlapping
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        boxShadow: const [
                          BoxShadow(
                              color: AppColors.shadow,
                              blurRadius: 8,
                              offset: Offset(0, -2)),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/checkout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28)),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Checkout',
                                  style: AppTextStyles.buttonFilled
                                      .copyWith(fontSize: 16)),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded,
                                  color: AppColors.textOnPrimary,
                                  size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
          // ← Bottom nav preserved
          bottomNavigationBar: MegaBottomNav(
            currentIndex: 3,
            onTap: (i) {
              switch (i) {
                case 0:
                  Navigator.pushReplacementNamed(context, '/home');
                  break;
                case 1:
                  Navigator.pushReplacementNamed(context, '/reels');
                  break;
                case 2:
                  Navigator.pushReplacementNamed(context, '/post');
                  break;
                case 4:
                  Navigator.pushNamed(context, '/profile');
                  break;
              }
            },
          ),
        );
      },
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartEntry item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: item.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              placeholder: (ctx, url) =>
                  Container(color: AppColors.primarySurface),
              errorWidget: (ctx, url, err) =>
                  Container(color: AppColors.primarySurface),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.name,
                          style: AppTextStyles.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: AppColors.iconMuted, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(item.variant,
                    style: AppTextStyles.brandName),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: AppTextStyles.price.copyWith(
                            fontSize: 17, color: AppColors.primary)),
                    _QtyControl(
                      qty: item.quantity,
                      onMinus: onDecrement,
                      onPlus: onIncrement,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyControl extends StatelessWidget {
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _QtyControl(
      {required this.qty, required this.onMinus, required this.onPlus});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyBtn(icon: Icons.remove, onTap: onMinus),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('$qty',
                style: AppTextStyles.productName.copyWith(fontSize: 15)),
          ),
          _QtyBtn(icon: Icons.add, onTap: onPlus),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: AppColors.textPrimary),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: labelStyle ??
                AppTextStyles.brandName.copyWith(fontSize: 13)),
        Text(value,
            style: valueStyle ??
                AppTextStyles.productName.copyWith(
                    fontSize: 14,
                    color: valueColor ?? AppColors.textPrimary)),
      ],
    );
  }
}

class _EmptyCart extends StatelessWidget {
  final VoidCallback onShop;

  const _EmptyCart({required this.onShop});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_cart_outlined,
                size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text('Your cart is empty',
              style: AppTextStyles.sectionTitle.copyWith(fontSize: 20)),
          const SizedBox(height: 8),
          Text('Discover products and add them here',
              style: AppTextStyles.brandName),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: onShop,
            icon: const Icon(Icons.explore_outlined,
                color: AppColors.textOnPrimary),
            label: Text('Browse Products',
                style: AppTextStyles.buttonFilled),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
