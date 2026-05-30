import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/state/cart_state.dart';

/// 3-step checkout flow: Address → Payment → Done.
///
/// Uses a step indicator at the top; each step is rendered as a separate
/// widget. The CTA button at the bottom advances the step.
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int _step = 0; // 0 = Address, 1 = Payment, 2 = Complete
  int _selectedAddress = 0;
  final _cardCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();

  final List<_Address> _addresses = [
    const _Address(
      label: 'Home',
      tag: 'DEFAULT',
      name: 'Budi Santoso',
      phone: '0812-3456-7890',
      address: '123 Main Street, New York, NY 10001',
    ),
    const _Address(
      label: 'Office',
      tag: null,
      name: 'Budi Santoso',
      phone: '0812-3456-7890',
      address: '456 Business Ave, New York, NY 10002',
    ),
  ];

  @override
  void dispose() {
    _cardCtrl.dispose();
    _cvvCtrl.dispose();
    _expiryCtrl.dispose();
    super.dispose();
  }

  String get _ctaLabel {
    if (_step == 0) return 'Continue to Payment';
    if (_step == 1) return 'Confirm Order';
    return 'Complete';
  }

  void _advance() {
    if (_step < 2) {
      setState(() => _step++);
    } else {
      // Navigate to order success
      Navigator.pushReplacementNamed(context, '/order-status',
          arguments: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            if (_step > 0) {
              setState(() => _step--);
            } else {
              Navigator.pop(context);
            }
          },
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
        ),
        title: Text('Checkout', style: AppTextStyles.productName.copyWith(fontSize: 18)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step indicator
                _StepIndicator(currentStep: _step),
                const SizedBox(height: 24),
                if (_step == 0) _buildAddressStep(),
                if (_step == 1) _buildPaymentStep(),
                if (_step == 2) _buildConfirmStep(),
              ],
            ),
          ),
          // CTA button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
              color: AppColors.background,
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _advance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28)),
                    elevation: 0,
                  ),
                  child: Text(_ctaLabel,
                      style:
                          AppTextStyles.buttonFilled.copyWith(fontSize: 16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAddAddressSheet() {
    final labelCtrl = TextEditingController();
    final nameCtrl = TextEditingController(text: 'Budi Santoso');
    final phoneCtrl = TextEditingController(text: '0812-3456-7890');
    final addressCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 16,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.add_location_alt_rounded,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text('Add New Address',
                      style: AppTextStyles.sectionTitle.copyWith(fontSize: 18)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: labelCtrl,
                decoration: InputDecoration(
                  hintText: 'Label (e.g., Home, Office)',
                  hintStyle: AppTextStyles.brandName.copyWith(fontSize: 13),
                  prefixIcon: const Icon(Icons.label_outline_rounded, color: AppColors.iconMuted, size: 20),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  hintText: 'Recipient Name',
                  hintStyle: AppTextStyles.brandName.copyWith(fontSize: 13),
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.iconMuted, size: 20),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                decoration: InputDecoration(
                  hintText: 'Phone Number',
                  hintStyle: AppTextStyles.brandName.copyWith(fontSize: 13),
                  prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.iconMuted, size: 20),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Full Address details',
                  hintStyle: AppTextStyles.brandName.copyWith(fontSize: 13),
                  prefixIcon: const Icon(Icons.place_rounded, color: AppColors.iconMuted, size: 20),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppColors.divider),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('Cancel',
                          style: AppTextStyles.productName
                              .copyWith(fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final label = labelCtrl.text.trim();
                        final name = nameCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();
                        final address = addressCtrl.text.trim();
                        if (label.isEmpty ||
                            name.isEmpty ||
                            phone.isEmpty ||
                            address.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Please fill all fields',
                                style: AppTextStyles.brandName
                                    .copyWith(color: AppColors.textOnPrimary),
                              ),
                              backgroundColor: AppColors.badgeSale,
                            ),
                          );
                          return;
                        }
                        setState(() {
                          _addresses.add(_Address(
                            label: label,
                            tag: null,
                            name: name,
                            phone: phone,
                            address: address,
                          ));
                          _selectedAddress = _addresses.length - 1;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: Text('Save Address',
                          style: AppTextStyles.buttonFilled
                              .copyWith(fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddressStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Shipping Address',
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 22)),
        const SizedBox(height: 16),
        ..._addresses.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AddressCard(
                address: e.value,
                isSelected: _selectedAddress == e.key,
                onTap: () => setState(() => _selectedAddress = e.key),
              ),
            )),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _openAddAddressSheet,
          icon: const Icon(Icons.add_rounded, color: AppColors.primary),
          label: Text('Add New Address',
              style: AppTextStyles.buttonOutlined),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment Information',
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 22)),
        const SizedBox(height: 20),
        _PayField(
            ctrl: _cardCtrl,
            hint: 'Card Number',
            icon: Icons.credit_card_rounded),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _PayField(
                    ctrl: _expiryCtrl,
                    hint: 'MM/YY',
                    icon: Icons.calendar_month_outlined)),
            const SizedBox(width: 12),
            Expanded(
                child: _PayField(
                    ctrl: _cvvCtrl,
                    hint: 'CVV',
                    icon: Icons.lock_outline_rounded,
                    obscure: true)),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _SummaryRow2('Subtotal', '\$${CartStateProvider.of(context).subtotal.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              _SummaryRow2('Shipping', 'Free',
                  valueColor: AppColors.primary),
              const SizedBox(height: 8),
              _SummaryRow2('Tax', '\$${CartStateProvider.of(context).tax.toStringAsFixed(2)}'),
              const Divider(height: 20, color: AppColors.divider),
              _SummaryRow2('Total', '\$${CartStateProvider.of(context).total.toStringAsFixed(2)}',
                  bold: true, valueColor: AppColors.primary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Confirm Order',
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 22)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Shipping Address',
                  style: AppTextStyles.productName.copyWith(fontSize: 14)),
              const SizedBox(height: 4),
              Text(_addresses[_selectedAddress].address,
                  style: AppTextStyles.brandName),
              const Divider(height: 20, color: AppColors.divider),
              Text('Payment Method',
                  style: AppTextStyles.productName.copyWith(fontSize: 14)),
              const SizedBox(height: 4),
              Text('Credit/Debit Card', style: AppTextStyles.brandName),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final labels = ['Address', 'Payment', 'Complete'];
    return Row(
      children: List.generate(3, (i) {
        final isActive = i <= currentStep;
        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : AppColors.primarySurface,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: AppTextStyles.badge.copyWith(
                            fontSize: 14,
                            color: isActive
                                ? AppColors.textOnPrimary
                                : AppColors.iconMuted),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(labels[i],
                      style: AppTextStyles.brandName.copyWith(
                          fontSize: 11,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.iconMuted)),
                ],
              ),
              if (i < 2)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 18),
                    color: i < currentStep
                        ? AppColors.primary
                        : AppColors.divider,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _Address {
  final String label;
  final String? tag;
  final String name;
  final String phone;
  final String address;

  const _Address({
    required this.label,
    this.tag,
    required this.name,
    required this.phone,
    required this.address,
  });
}

class _AddressCard extends StatelessWidget {
  final _Address address;
  final bool isSelected;
  final VoidCallback onTap;

  const _AddressCard(
      {required this.address, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2),
            boxShadow: const [
              BoxShadow(
                  color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(address.label,
                      style: AppTextStyles.productName.copyWith(fontSize: 15)),
                  if (address.tag != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(address.tag!,
                          style: AppTextStyles.badge.copyWith(
                              fontSize: 10, color: AppColors.primary)),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: isSelected ? AppColors.primary : AppColors.iconMuted,
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(address.name, style: AppTextStyles.productName),
              Text(address.phone, style: AppTextStyles.brandName),
              const SizedBox(height: 6),
              Text(address.address,
                  style: AppTextStyles.brandName.copyWith(height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final bool obscure;

  const _PayField(
      {required this.ctrl,
      required this.hint,
      required this.icon,
      this.obscure = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.brandName.copyWith(fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.iconMuted, size: 20),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _SummaryRow2 extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _SummaryRow2(this.label, this.value,
      {this.valueColor, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: bold
                ? AppTextStyles.sectionTitle.copyWith(fontSize: 16)
                : AppTextStyles.brandName),
        Text(value,
            style: bold
                ? AppTextStyles.price.copyWith(
                    fontSize: 18,
                    color: valueColor ?? AppColors.textPrimary)
                : AppTextStyles.productName.copyWith(
                    fontSize: 14,
                    color: valueColor ?? AppColors.textPrimary)),
      ],
    );
  }
}
