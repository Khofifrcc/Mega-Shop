import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/reel.dart';

class EditReelPage extends StatefulWidget {
  const EditReelPage({super.key});

  @override
  State<EditReelPage> createState() => _EditReelPageState();
}

class _EditReelPageState extends State<EditReelPage> {
  late TextEditingController _captionCtrl;
  late TextEditingController _productNameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _originalPriceCtrl;
  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_isInitialized) return;

    final reel = ModalRoute.of(context)!.settings.arguments as Reel;

    _captionCtrl = TextEditingController(text: reel.caption);
    _productNameCtrl = TextEditingController(text: reel.productName);
    _priceCtrl = TextEditingController(text: reel.price.toString());
    _originalPriceCtrl = TextEditingController(
      text: reel.originalPrice?.toString() ?? '',
    );

    _isInitialized = true;
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    _productNameCtrl.dispose();
    _priceCtrl.dispose();
    _originalPriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveReel(Reel reel) async {
    final caption = _captionCtrl.text.trim();
    final productName = _productNameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim());
    final originalPrice = _originalPriceCtrl.text.trim().isEmpty
        ? null
        : double.tryParse(_originalPriceCtrl.text.trim());

    if (caption.isEmpty || productName.isEmpty || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid reel data.'),
        ),
      );
      return;
    }

    try {
      setState(() => _isSaving = true);

      await FirebaseFirestore.instance
          .collection('reels')
          .doc(reel.id)
          .update({
        'caption': caption,
        'productName': productName,
        'price': price,
        'originalPrice': originalPrice,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reel updated successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reel = ModalRoute.of(context)!.settings.arguments as Reel;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Edit Reel',
          style: AppTextStyles.sectionTitle.copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _EditField(
              controller: _productNameCtrl,
              label: 'Product Name',
              icon: Icons.inventory_2_outlined,
            ),
            const SizedBox(height: 14),
            _EditField(
              controller: _captionCtrl,
              label: 'Description',
              icon: Icons.description_outlined,
              maxLines: 4,
            ),
            const SizedBox(height: 14),
            _EditField(
              controller: _priceCtrl,
              label: 'Price',
              icon: Icons.attach_money_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 14),
            _EditField(
              controller: _originalPriceCtrl,
              label: 'Original Price (Optional)',
              icon: Icons.price_change_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : () => _saveReel(reel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Save Changes',
                        style:
                            AppTextStyles.buttonFilled.copyWith(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;

  const _EditField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.iconMuted),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
