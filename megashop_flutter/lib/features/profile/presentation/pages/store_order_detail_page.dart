import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class StoreOrderDetailPage extends StatefulWidget {
  const StoreOrderDetailPage({super.key});

  @override
  State<StoreOrderDetailPage> createState() => _StoreOrderDetailPageState();
}

class _StoreOrderDetailPageState extends State<StoreOrderDetailPage> {
  final _trackingCtrl = TextEditingController();
  String _selectedStatus = 'pending';
  bool _isUpdating = false;

  final List<String> _statuses = [
    'pending',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
  ];

  @override
  void dispose() {
    _trackingCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateOrder(String orderId) async {
    try {
      setState(() => _isUpdating = true);

      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': _selectedStatus,
        'trackingNumber': _trackingCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order updated successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update order: $e'),
          backgroundColor: AppColors.badgeSale,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

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
          'Manage Order',
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


          // Initialize state once
          if (_trackingCtrl.text.isEmpty && data['trackingNumber'] != null) {
            _trackingCtrl.text = data['trackingNumber'];
          }
          if (!_statuses.contains(_selectedStatus)) {
            _selectedStatus = 'pending';
          } else if (data['status'] != null && _selectedStatus == 'pending' && _trackingCtrl.text.isEmpty) {
             _selectedStatus = data['status'];
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order ID 
                Text('Order #${orderId.substring(0, 8).toUpperCase()}', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 20),

                // Update Status Section
                Text('Update Order Status', style: AppTextStyles.brandName.copyWith(fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatus,
                      isExpanded: true,
                      dropdownColor: AppColors.surface,
                      items: _statuses.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status.toUpperCase(), style: AppTextStyles.productName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedStatus = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Update Tracking
                Text('Tracking Number', style: AppTextStyles.brandName.copyWith(fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _trackingCtrl,
                  decoration: InputDecoration(
                    hintText: 'Enter tracking number (e.g. JNT123456789)',
                    hintStyle: AppTextStyles.brandName.copyWith(fontSize: 13),
                    prefixIcon: const Icon(CupertinoIcons.barcode, color: AppColors.iconMuted, size: 20),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isUpdating ? null : () => _updateOrder(orderId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isUpdating
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Update Order', style: AppTextStyles.buttonFilled.copyWith(fontSize: 15)),
                  ),
                ),

                const SizedBox(height: 32),
                Text('Items Ordered', style: AppTextStyles.sectionTitle.copyWith(fontSize: 18)),
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
                      Text(shipping['name'] ?? '', style: AppTextStyles.productName),
                      const SizedBox(height: 4),
                      Text(shipping['phone'] ?? '', style: AppTextStyles.brandName),
                      const SizedBox(height: 4),
                      Text(
                        shipping['address'] ?? '',
                        style: AppTextStyles.brandName.copyWith(height: 1.5),
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
              width: 50,
              height: 50,
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
