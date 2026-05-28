import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/state/cart_state.dart';

/// Order status page — shows Success or Failed state based on route argument.
///
/// Route argument: [bool] isSuccess
class OrderStatusPage extends StatelessWidget {
  const OrderStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isSuccess = (ModalRoute.of(context)?.settings.arguments as bool?) ?? true;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: isSuccess
              ? _SuccessContent(
                  onViewOrder: () =>
                      Navigator.pushReplacementNamed(context, '/home'),
                  onGoHome: () {
                    CartStateProvider.of(context).clear();
                    Navigator.pushReplacementNamed(context, '/home');
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
}

class _SuccessContent extends StatelessWidget {
  final VoidCallback onViewOrder;
  final VoidCallback onGoHome;

  const _SuccessContent(
      {required this.onViewOrder, required this.onGoHome});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadow,
                blurRadius: 20,
                offset: Offset(0, 8))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                onPressed: onGoHome,
                icon: const Icon(Icons.close_rounded,
                    color: AppColors.iconMuted),
              ),
            ),
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_bag_rounded,
                  color: AppColors.primary, size: 56),
            ),
            const SizedBox(height: 20),
            Text('Order Berhasil!',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 24)),
            const SizedBox(height: 8),
            Text('Terima kasih telah berbelanja di MegaShop.',
                style: AppTextStyles.brandName,
                textAlign: TextAlign.center),
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
                  Text('Nomor Pesanan',
                      style: AppTextStyles.brandName.copyWith(fontSize: 13)),
                  Text('#ORD-9824XQ',
                      style: AppTextStyles.productName),
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
                      borderRadius: BorderRadius.circular(28)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Lihat Pesanan',
                        style: AppTextStyles.buttonFilled.copyWith(fontSize: 15)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded,
                        color: AppColors.textOnPrimary, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onGoHome,
              child: Text('Kembali ke Beranda',
                  style: AppTextStyles.buttonOutlined.copyWith(fontSize: 14)),
            ),
          ],
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
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadow,
                blurRadius: 20,
                offset: Offset(0, 8))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded,
                    color: AppColors.iconMuted),
              ),
            ),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.badgeSale.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: AppColors.badgeSale, size: 48),
            ),
            const SizedBox(height: 20),
            Text('Gagal',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              'Maaf, terjadi kesalahan saat memproses pesanan Anda. '
              'Silakan periksa koneksi atau metode pembayaran.',
              style: AppTextStyles.brandName.copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.help_outline_rounded,
                    color: AppColors.iconMuted, size: 16),
                const SizedBox(width: 6),
                Text('Hubungi Customer Service',
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
                icon: const Icon(Icons.refresh_rounded,
                    color: AppColors.textOnPrimary),
                label: Text('Coba Lagi',
                    style: AppTextStyles.buttonFilled.copyWith(fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.badgeSale,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
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
