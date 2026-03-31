import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/custom_background.dart';
import '../../../../providers/cart_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPaymentMethod = 'cash';
  String? selectedWalletName;
  String? selectedWalletAccount;
  final TextEditingController _receiptController = TextEditingController();
  bool isImageAttached = false;

  final List<Map<String, String>> wallets = [
    {'name': 'خدمة حاسب - الكريمي', 'account': '123456789'},
    {'name': 'محفظة بنك القطيبي', 'account': '987654321'},
    {'name': 'فلوسك', 'account': '777777777'},
    {'name': 'العمقي للصرافة', 'account': '254125233'}
  ];

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    const double deliveryFee = 500;
    final double grandTotal = cart.totalPrice + deliveryFee;

    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomBackground(
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(context, cart),
                Expanded(
                  child: cart.items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.shopping_cart_outlined,
                                color: Colors.white24,
                                size: 70,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "السلة فارغة 🛒",
                                style: GoogleFonts.cairo(
                                  color: Colors.white54,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                          children: [
                            _buildCouponSection(),
                            const SizedBox(height: 15),
                            _buildAddressSection(),
                            const SizedBox(height: 15),
                            _buildPhoneSection(),
                            const SizedBox(height: 15),
                            _buildNotesSection(),
                            const SizedBox(height: 15),
                            _buildPaymentMethodsSection(),
                            const SizedBox(height: 25),
                            _buildOrderTable(cart),
                            const SizedBox(height: 10),
                            _buildOrderSummary(
                              cart.totalPrice,
                              deliveryFee,
                              grandTotal,
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                ),
                _buildBottomAction(context, cart, deliveryFee, grandTotal),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, CartProvider cart) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Text(
            "تأكيد الطلب",
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: () {
              cart.clearCart();
              context.pop();
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2640).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: child,
    );
  }

  Widget _buildSectionRow({
    required IconData icon,
    required Color iconColor,
    required Widget content,
    Widget? action,
  }) {
    return _buildCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(child: content),
          if (action != null) action,
        ],
      ),
    );
  }

  Widget _buildCouponSection() {
    return _buildSectionRow(
      icon: Icons.local_activity_outlined,
      iconColor: const Color(0xFFFF416C),
      content: Text(
        "هل لديك قسيمة تخفيض؟",
        style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
      ),
      action: InkWell(
        onTap: () {},
        child: Text(
          "اضافة",
          style: GoogleFonts.cairo(
            color: const Color(0xFF0F55E8),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return _buildSectionRow(
      icon: Icons.location_on_outlined,
      iconColor: const Color(0xFFFF416C),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "عنوان التوصيل:",
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            "المساكن",
            style: GoogleFonts.cairo(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
      action: InkWell(
        onTap: () {},
        child: Text(
          "تغيير",
          style: GoogleFonts.cairo(
            color: const Color(0xFF0F55E8),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneSection() {
    return _buildSectionRow(
      icon: Icons.phone_outlined,
      iconColor: const Color(0xFFFF416C),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "رقم التواصل الخاص بعنوان التوصيل",
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            "774807553",
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return _buildSectionRow(
      icon: Icons.notes_outlined,
      iconColor: const Color(0xFFFF416C),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "ملاحظات الطلب",
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            "لا يوجد ملاحظة",
            style: GoogleFonts.cairo(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
      action: InkWell(
        onTap: () {},
        child: Text(
          "اضافة",
          style: GoogleFonts.cairo(
            color: const Color(0xFF0F55E8),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF416C).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Color(0xFFFF416C),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "الدفع  ( الدفع عند الاستلام )",
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.white.withOpacity(0.1), height: 1),
          const SizedBox(height: 10),
          _buildRadioOption("الدفع عند الاستلام", 'cash'),
          _buildRadioOption("الدفع من رصيدي ( 0 )", 'balance'),
          _buildRadioOption("الدفع استخدام المحفظة الإلكترونية", 'wallet'),
          if (_selectedPaymentMethod == 'wallet' && selectedWalletName != null) ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "الرجاء تحويل المبلغ إلى $selectedWalletAccount وإرفاق السند.",
                    style: GoogleFonts.cairo(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _receiptController,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "رقم السند أو رقم العملية",
                      hintStyle: GoogleFonts.cairo(color: Colors.white30, fontSize: 13),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        isImageAttached = !isImageAttached;
                      });
                    },
                    icon: Icon(
                      isImageAttached ? Icons.check_circle : Icons.upload_file,
                      color: isImageAttached ? Colors.green : Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      isImageAttached ? "تم إرفاق الصورة ✅" : "إرفاق صورة الإيداع",
                      style: GoogleFonts.cairo(
                        color: isImageAttached ? Colors.green : Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isImageAttached ? Colors.green : Colors.white.withOpacity(0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRadioOption(String title, String value) {
    bool isSelected = _selectedPaymentMethod == value;
    return InkWell(
      onTap: () {
        setState(() => _selectedPaymentMethod = value);
        if (value == 'wallet') {
          _showWalletsBottomSheet(context);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFFE58B29) : Colors.white54,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
            ),
            if (value == 'wallet') ...[
              const Spacer(),
              const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white54,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTable(CartProvider cart) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  "المنتج",
                  style: GoogleFonts.cairo(color: Colors.white54, fontSize: 11),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  "السعر",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(color: Colors.white54, fontSize: 11),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  "الكمية",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(color: Colors.white54, fontSize: 11),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  "الإجمالي",
                  textAlign: TextAlign.left,
                  style: GoogleFonts.cairo(color: Colors.white54, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        Divider(color: Colors.white.withOpacity(0.1), height: 1),
        ...cart.items.map((item) {
          final double total = item.price * item.quantity;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    item.name,
                    style:
                        GoogleFonts.cairo(color: Colors.white, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    "${item.price.toInt()}",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    "${item.quantity}",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    "${total.toInt()}",
                    textAlign: TextAlign.left,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        Divider(color: Colors.white.withOpacity(0.1), height: 1),
      ],
    );
  }

  Widget _buildOrderSummary(
    double subtotal,
    double deliveryFee,
    double grandTotal,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "الإجمالي",
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
              ),
              Row(
                children: [
                  Text(
                    "${subtotal.toInt()}",
                    style:
                        GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                  ),
                  Text(
                    " ر.ي",
                    style: GoogleFonts.cairo(
                        color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "التوصيل",
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
              ),
              Row(
                children: [
                  Text(
                    "${deliveryFee.toInt()}",
                    style:
                        GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                  ),
                  Text(
                    " ر.ي",
                    style: GoogleFonts.cairo(
                        color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE58B29),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "الإجمالي الكلي",
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${grandTotal.toInt()}",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2.0),
                    child: Text(
                      "ر.ي",
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showWalletsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1A34),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          padding: const EdgeInsets.only(bottom: 20, top: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Text(
                "اختر المحفظة الإلكترونية",
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: wallets.length,
                itemBuilder: (context, index) {
                  final wallet = wallets[index];
                  bool isWalletSelected = selectedWalletName == wallet['name'];
                  
                  return InkWell(
                    onTap: () {
                      this.setState(() {
                        selectedWalletName = wallet['name'];
                        selectedWalletAccount = wallet['account'];
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.account_balance_wallet,
                                color: Color(0xFFE58B29),
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  wallet['name']!,
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      wallet['account']!,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    GestureDetector(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: wallet['account']!));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'تم نسخ رقم الحساب',
                                              style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
                                            ),
                                            backgroundColor: Colors.green.shade700,
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      child: const Icon(
                                        Icons.copy,
                                        color: Colors.white54,
                                        size: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isWalletSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: isWalletSelected ? const Color(0xFFE58B29) : Colors.white54,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      "إغلاق",
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomAction(
    BuildContext context,
    CartProvider cart,
    double deliveryFee,
    double grandTotal,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 15,
      ).copyWith(bottom: 25),
      decoration: BoxDecoration(
        color: const Color(0xFF140C36).withOpacity(0.95),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => context.pop(),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    "تعديل السلة",
                    style: GoogleFonts.cairo(
                      color: const Color(0xFFD32F2F),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: cart.items.isEmpty
                  ? null
                  : () {
                      if (_selectedPaymentMethod == 'wallet') {
                        if (_receiptController.text.isEmpty && !isImageAttached) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'فشل الدفع: الرجاء إدخال رقم السند أو إرفاق صورة الإيداع لتأكيد الدفع.',
                                style: GoogleFonts.cairo(color: Colors.white),
                              ),
                              backgroundColor: Colors.red.shade700,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          return;
                        }
                      }

                      final orderData = {
                        'orderId':
                            '#${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                        'items': List.from(cart.items),
                        'subtotal': cart.totalPrice,
                        'deliveryFee': deliveryFee,
                        'total': grandTotal,
                      };
                      context.push('/order-status', extra: orderData);
                      cart.clearCart();
                    },
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: cart.items.isEmpty
                      ? Colors.grey.shade700
                      : const Color(0xFFD32F2F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    "تنفيذ الطلب",
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
