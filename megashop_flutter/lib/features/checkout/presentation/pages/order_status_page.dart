import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/state/cart_state.dart';
import '../../../home/presentation/pages/home_page.dart';

/// Order status page — shows Success or Failed state based on route argument.
///
/// Route argument: [bool] isSuccess
class OrderStatusPage extends StatefulWidget {
  const OrderStatusPage({super.key});

  @override
  State<OrderStatusPage> createState() => _OrderStatusPageState();
}

class _OrderStatusPageState extends State<OrderStatusPage> {
  bool _hasShownSuccessPopup = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final isSuccess =
        (ModalRoute.of(context)?.settings.arguments as bool?) ?? true;
    if (isSuccess && !_hasShownSuccessPopup) {
      _hasShownSuccessPopup = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showSuccessPopup();
        }
      });
    }
  }

  Future<void> _showSuccessPopup() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _OrderSuccessPopup(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess =
        (ModalRoute.of(context)?.settings.arguments as bool?) ?? true;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: isSuccess
              ? _SuccessContent(
                  onViewOrder: () => _showOrderDetailComingSoon(context),
                  onGoHome: () {
                    CartStateProvider.of(context).clear();
                    _replaceWithSmoothRoute(context, '/home');
                  },
                )
              : _FailedContent(
                  onRetry: () =>
                      Navigator.pushReplacementNamed(context, '/checkout'),
                  onClose: () => Navigator.pop(context),
                ),
        ),
      ),
    );
  }

  void _replaceWithSmoothRoute(BuildContext context, String routeName) {
    final target = switch (routeName) {
      _ => const HomePage(),
    };

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => target,
        settings: RouteSettings(name: routeName),
        transitionDuration: const Duration(milliseconds: 360),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0.02),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _showOrderDetailComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order detail page will be added soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _OrderSuccessPopup extends StatefulWidget {
  const _OrderSuccessPopup();

  @override
  State<_OrderSuccessPopup> createState() => _OrderSuccessPopupState();
}

class _OrderSuccessPopupState extends State<_OrderSuccessPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: FadeTransition(
        opacity: _opacity,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            width: 220,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 30,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.check_mark_circled_solid,
                    color: AppColors.primary,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Order Successful',
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessContent extends StatelessWidget {
  final VoidCallback onViewOrder;
  final VoidCallback onGoHome;

  const _SuccessContent({required this.onViewOrder, required this.onGoHome});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 18 * (1 - value)),
              child: Transform.scale(
                scale: 0.96 + (0.04 * value),
                child: child,
              ),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 24,
                  offset: Offset(0, 10))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: IconButton(
                    onPressed: onGoHome,
                    icon: const Icon(CupertinoIcons.xmark,
                        color: AppColors.iconMuted),
                  ),
                ),
              ),
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.bag_fill,
                    color: AppColors.primary, size: 56),
              ),
              const SizedBox(height: 20),
              Text('Order Successful!',
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 24)),
              const SizedBox(height: 8),
              Text('Thank you for shopping at MegaShop.',
                  style: AppTextStyles.brandName, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order Number',
                        style: AppTextStyles.brandName.copyWith(fontSize: 13)),
                    Text('#ORD-9824XQ', style: AppTextStyles.productName),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onViewOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('View Order',
                          style: AppTextStyles.buttonFilled
                              .copyWith(fontSize: 15)),
                      const SizedBox(width: 8),
                      const Icon(CupertinoIcons.arrow_right,
                          color: AppColors.textOnPrimary, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onGoHome,
                  child: Text('Back to Home',
                      style:
                          AppTextStyles.buttonOutlined.copyWith(fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FailedContent extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onClose;

  const _FailedContent({required this.onRetry, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadow, blurRadius: 20, offset: Offset(0, 8))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: IconButton(
                  onPressed: onClose,
                  icon: const Icon(CupertinoIcons.xmark,
                      color: AppColors.iconMuted),
                ),
              ),
            ),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.badgeSale.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.exclamationmark_circle,
                  color: AppColors.badgeSale, size: 48),
            ),
            const SizedBox(height: 20),
            Text('Order Failed',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              'Sorry, an error occurred while processing your order. '
              'Please check your connection or payment method.',
              style: AppTextStyles.brandName.copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.question_circle,
                    color: AppColors.iconMuted, size: 16),
                const SizedBox(width: 6),
                Text('Contact Customer Support',
                    style: AppTextStyles.brandName
                        .copyWith(color: AppColors.iconMuted, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(CupertinoIcons.refresh,
                    color: AppColors.textOnPrimary, size: 18),
                label: Text('Try Again',
                    style: AppTextStyles.buttonFilled.copyWith(fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.badgeSale,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
