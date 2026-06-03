import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final orderId = ModalRoute.of(context)?.settings.arguments as String?;

    if (orderId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: Text('Invalid Order ID')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Order Details',
          style: AppTextStyles.sectionTitle.copyWith(fontSize: 20),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('orders').doc(orderId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                'Failed to load order details.',
                style: AppTextStyles.brandName.copyWith(color: AppColors.badgeSale),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final items = (data['items'] as List<dynamic>?) ?? [];
          final shipping = data['shippingAddress'] as Map<String, dynamic>? ?? {};
          final subtotal = (data['subtotal'] ?? 0).toDouble();
          final tax = (data['tax'] ?? 0).toDouble();
          final total = (data['total'] ?? 0).toDouble();
          final status = data['status'] ?? 'pending';
          
          DateTime? createdAt;
          if (data['createdAt'] is Timestamp) {
            createdAt = (data['createdAt'] as Timestamp).toDate();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order ID & Status Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Order Number', style: AppTextStyles.brandName),
                          Text(
                            '#${orderId.substring(0, 8).toUpperCase()}',
                            style: AppTextStyles.productName,
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.divider, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Date', style: AppTextStyles.brandName),
                          Text(
                            createdAt != null 
                              ? '${_monthStr(createdAt.month)} ${createdAt.day}, ${createdAt.year}' 
                              : '-',
                            style: AppTextStyles.productName,
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.divider, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Status', style: AppTextStyles.brandName),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status.toString().toUpperCase(),
                              style: AppTextStyles.badge.copyWith(
                                color: _getStatusColor(status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (data['trackingNumber'] != null && data['trackingNumber'].toString().isNotEmpty) ...[
                        const Divider(color: AppColors.divider, height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Tracking No.', style: AppTextStyles.brandName),
                            Text(
                              data['trackingNumber'],
                              style: AppTextStyles.productName.copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text('Items', style: AppTextStyles.sectionTitle.copyWith(fontSize: 18)),
                const SizedBox(height: 12),
                
                // Items List
                ...items.map((item) => _OrderItemCard(item: item as Map<String, dynamic>)),

                const SizedBox(height: 24),
                Text('Shipping Details', style: AppTextStyles.sectionTitle.copyWith(fontSize: 18)),
                const SizedBox(height: 12),
                
                // Shipping Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.place_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            shipping['label'] ?? 'Home',
                            style: AppTextStyles.productName,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(shipping['name'] ?? '', style: AppTextStyles.productName.copyWith(fontSize: 14)),
                      Text(shipping['phone'] ?? '', style: AppTextStyles.brandName),
                      const SizedBox(height: 4),
                      Text(
                        shipping['address'] ?? '',
                        style: AppTextStyles.brandName.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Text('Payment Summary', style: AppTextStyles.sectionTitle.copyWith(fontSize: 18)),
                const SizedBox(height: 12),
                
                // Payment Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _SummaryRow('Payment Method', data['paymentMethod'] ?? 'Card'),
                      const Divider(color: AppColors.divider, height: 24),
                      _SummaryRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
                      const SizedBox(height: 8),
                      _SummaryRow('Shipping', 'Free', valueColor: AppColors.primary),
                      const SizedBox(height: 8),
                      _SummaryRow('Tax', '\$${tax.toStringAsFixed(2)}'),
                      const Divider(color: AppColors.divider, height: 24),
                      _SummaryRow(
                        'Total',
                        '\$${total.toStringAsFixed(2)}',
                        bold: true,
                        valueColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orangeAccent;
      case 'processing':
        return Colors.blueAccent;
      case 'shipped':
        return Colors.purpleAccent;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return AppColors.iconMuted;
    }
  }

  String _monthStr(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return month >= 1 && month <= 12 ? months[month - 1] : '';
  }
}

class _OrderItemCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _OrderItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final price = (item['price'] ?? 0).toDouble();
    final quantity = item['quantity'] ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: item['imageUrl'] ?? '',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppColors.primarySurface),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.primarySurface,
                child: const Icon(Icons.image_not_supported_outlined, color: AppColors.iconMuted),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? '',
                  style: AppTextStyles.productName.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Variant: ${item['variant'] ?? 'Default'}',
                  style: AppTextStyles.brandName.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: AppTextStyles.price.copyWith(fontSize: 14),
                    ),
                    Text(
                      'x$quantity',
                      style: AppTextStyles.productName.copyWith(fontSize: 13),
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

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _SummaryRow(this.label, this.value, {this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: bold ? AppTextStyles.productName : AppTextStyles.brandName,
        ),
        Text(
          value,
          style: bold
              ? AppTextStyles.sectionTitle.copyWith(fontSize: 16, color: valueColor)
              : AppTextStyles.productName.copyWith(color: valueColor),
        ),
      ],
    );
  }
}
