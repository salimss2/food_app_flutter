import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/widgets/custom_background.dart';
import '../../../../providers/cart_provider.dart';
import '../../../../providers/schedule_provider.dart';
import '../../../../providers/order_provider.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/api/endpoints.dart';

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
  File? _receiptImage;

  // --- Coupon State ---
  final TextEditingController _couponController = TextEditingController();
  bool _isApplyingCoupon = false;

  // --- Schedule State ---
  DateTime? _scheduledDateTime;
  bool _isScheduled = false;

  // --- Delivery Fee State ---
  double _deliveryFee = 0.0;
  bool _isLoadingFee = true;
  String? _feeErrorMessage;

  final List<Map<String, String>> wallets = [
    {'name': 'kuraimi_service'.tr(), 'account': '123456789'},
    {'name': 'qutaibi_wallet'.tr(), 'account': '987654321'},
    {'name': 'floosak'.tr(), 'account': '777777777'},
    {'name': 'umqi_exchange'.tr(), 'account': '254125233'},
  ];

  @override
  void initState() {
    super.initState();
    // 🌟 Lifecycle Trigger: Auto-calculate fee when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateDeliveryFee();
    });
  }

  @override
  void dispose() {
    _receiptController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  // --- API Integration Logic ---
  Future<void> _calculateDeliveryFee() async {
    setState(() {
      _isLoadingFee = true;
      _feeErrorMessage = null;
    });

    try {
      final cart = Provider.of<CartProvider>(context, listen: false);
      double restaurantLat = 0.0;
      double restaurantLng = 0.0;

      if (cart.items.isNotEmpty) {
        restaurantLat = cart.items.first.restaurantLat;
        restaurantLng = cart.items.first.restaurantLng;
      }

      final prefs = await SharedPreferences.getInstance();
      double customerLat =
          prefs.getDouble('saved_lat') ?? prefs.getDouble('user_lat') ?? 0.0;
      double customerLng =
          prefs.getDouble('saved_lng') ?? prefs.getDouble('user_lng') ?? 0.0;

      final dio = DioClient().dio;
      final response = await dio.post(
        '${Endpoints.baseUrl}/delivery/calculate-fee',
        data: {
          "restaurant_lat": restaurantLat,
          "restaurant_lng": restaurantLng,
          "customer_lat": customerLat,
          "customer_lng": customerLng,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _deliveryFee = (response.data['delivery_fee'] as num).toDouble();
          _isLoadingFee = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _isLoadingFee = false;
        if (e.response?.statusCode == 400 && e.response?.data != null) {
          _feeErrorMessage = e.response?.data['message'] ?? "out_of_range".tr();
        } else {
          _feeErrorMessage = "delivery_calculation_error".tr();
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingFee = false;
        _feeErrorMessage = "unexpected_error".tr();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final double grandTotal = cart.totalPrice + _deliveryFee - cart.discountAmount;

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
                                "cart_empty".tr(),
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
                            const SizedBox(height: 15),
                            _buildAddressSection(),
                            const SizedBox(height: 15),
                            _buildPhoneSection(),
                            const SizedBox(height: 15),
                            _buildNotesSection(),
                            const SizedBox(height: 15),
                            _buildCouponSection(cart),
                            const SizedBox(height: 15),
                            _buildPaymentMethodsSection(),
                            const SizedBox(height: 15),
                            _buildScheduleSection(),
                            const SizedBox(height: 25),
                            _buildOrderTable(cart),
                            const SizedBox(height: 10),
                            _buildOrderSummary(
                              cart.totalPrice,
                              _deliveryFee,
                              cart.discountAmount,
                              grandTotal,
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                ),
                _buildBottomAction(context, cart, _deliveryFee, grandTotal),
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
            "confirm_order".tr(),
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

  Widget _buildAddressSection() {
    return _buildSectionRow(
      icon: Icons.location_on_outlined,
      iconColor: const Color(0xFFFF416C),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "delivery_address".tr(),
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            "delivery_address_value".tr(),
            style: GoogleFonts.cairo(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
      action: InkWell(
        onTap: () {},
        child: Text(
          "change".tr(),
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
            "delivery_phone".tr(),
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
            "order_notes".tr(),
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            "no_notes".tr(),
            style: GoogleFonts.cairo(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
      action: InkWell(
        onTap: () {},
        child: Text(
          "add".tr(),
          style: GoogleFonts.cairo(
            color: const Color(0xFF0F55E8),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildCouponSection(CartProvider cart) {
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
                  Icons.local_offer_outlined,
                  color: Color(0xFFFF416C),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "promo_code".tr().isNotEmpty && "promo_code".tr() != "promo_code"
                    ? "promo_code".tr()
                    : "رمز الترويج / الكوبون",
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                  child: TextField(
                    controller: _couponController,
                    enabled: cart.appliedCouponCode == null,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: "enter_coupon_hint".tr().isNotEmpty && "enter_coupon_hint".tr() != "enter_coupon_hint"
                          ? "enter_coupon_hint".tr()
                          : "أدخل رمز الكوبون",
                      hintStyle: GoogleFonts.cairo(
                        color: Colors.white30,
                        fontSize: 13,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (cart.appliedCouponCode != null)
                ElevatedButton(
                  onPressed: () {
                    cart.removeCoupon();
                    _couponController.clear();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    "remove".tr().isNotEmpty && "remove".tr() != "remove"
                        ? "remove".tr()
                        : "إزالة",
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: _isApplyingCoupon
                      ? null
                      : () async {
                          final code = _couponController.text.trim();
                          if (code.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "please_enter_coupon".tr().isNotEmpty && "please_enter_coupon".tr() != "please_enter_coupon"
                                      ? "please_enter_coupon".tr()
                                      : "يرجى إدخال رمز الكوبون أولاً",
                                  style: GoogleFonts.cairo(color: Colors.white),
                                ),
                                backgroundColor: Colors.red.shade700,
                              ),
                            );
                            return;
                          }
                          setState(() {
                            _isApplyingCoupon = true;
                          });
                          final (success, message) = await cart.applyCoupon(code);
                          if (mounted) {
                            setState(() {
                              _isApplyingCoupon = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  message,
                                  style: GoogleFonts.cairo(color: Colors.white),
                                ),
                                backgroundColor: success
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE58B29),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: _isApplyingCoupon
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          "apply".tr().isNotEmpty && "apply".tr() != "apply"
                              ? "apply".tr()
                              : "تطبيق",
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
            ],
          ),
          if (cart.appliedCouponCode != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  "coupon_applied_success".tr().isNotEmpty && "coupon_applied_success".tr() != "coupon_applied_success"
                      ? "coupon_applied_success".tr(namedArgs: {
                          'code': cart.appliedCouponCode!,
                          'discount': cart.discountAmount.toInt().toString(),
                          'currency': 'currency'.tr(),
                        })
                      : "تم تطبيق الكوبون (${cart.appliedCouponCode}) بنجاح خصم ${cart.discountAmount.toInt()} ${'currency'.tr()}",
                  style: GoogleFonts.cairo(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
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
                "payment_label".tr(),
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.white.withOpacity(0.1), height: 1),
          const SizedBox(height: 10),
          _buildRadioOption("pay_on_delivery".tr(), 'cash'),
          _buildRadioOption("pay_from_balance".tr(), 'balance'),
          _buildRadioOption("pay_with_wallet".tr(), 'bank_transfer'),
          if (_selectedPaymentMethod == 'bank_transfer' &&
              selectedWalletName != null) ...[
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
                    'transfer_amount_instruction'.tr(
                      namedArgs: {'account': selectedWalletAccount ?? ''},
                    ),
                    style: GoogleFonts.cairo(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _receiptController,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: "receipt_number_hint".tr(),
                      hintStyle: GoogleFonts.cairo(
                        color: Colors.white30,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final pickedFile = await picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (pickedFile != null) {
                        setState(() {
                          _receiptImage = File(pickedFile.path);
                        });
                      }
                    },
                    icon: Icon(
                      _receiptImage != null
                          ? Icons.check_circle
                          : Icons.upload_file,
                      color: _receiptImage != null
                          ? Colors.green
                          : Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      _receiptImage != null
                          ? 'attached_file'.tr(
                              namedArgs: {
                                'filename': _receiptImage!.path.split('/').last,
                              },
                            )
                          : "attach_receipt".tr(),
                      style: GoogleFonts.cairo(
                        color: _receiptImage != null
                            ? Colors.green
                            : Colors.white,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: _receiptImage != null
                            ? Colors.green
                            : Colors.white.withOpacity(0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 10,
                      ),
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
        if (value == 'bank_transfer') {
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
            if (value == 'bank_transfer') ...[
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
                  "product".tr(),
                  style: GoogleFonts.cairo(color: Colors.white54, fontSize: 11),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  "price".tr(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(color: Colors.white54, fontSize: 11),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  "quantity".tr(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(color: Colors.white54, fontSize: 11),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  "total".tr(),
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
                    style: GoogleFonts.cairo(color: Colors.white, fontSize: 12),
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
    double discountAmount,
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
                "subtotal".tr(),
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
              ),
              Row(
                children: [
                  Text(
                    "${subtotal.toInt()}",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    " " + "currency".tr(),
                    style: GoogleFonts.cairo(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
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
                "delivery".tr(),
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
              ),
              Row(
                children: [
                  if (_isLoadingFee)
                    const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else if (_feeErrorMessage != null)
                    const Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 18,
                    )
                  else
                    Text(
                      "${deliveryFee.toInt()}",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  if (!_isLoadingFee && _feeErrorMessage == null)
                    Text(
                      " ${'currency'.tr()}",
                      style: GoogleFonts.cairo(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (_feeErrorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 10, right: 10),
            child: Text(
              _feeErrorMessage!,
              style: GoogleFonts.cairo(color: Colors.redAccent, fontSize: 11),
            ),
          ),
        if (discountAmount > 0) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "discount".tr().isNotEmpty && "discount".tr() != "discount"
                      ? "discount".tr()
                      : "الخصم",
                  style: GoogleFonts.cairo(color: Colors.redAccent, fontSize: 13),
                ),
                Row(
                  children: [
                    Text(
                      "-${discountAmount.toInt()}",
                      style: GoogleFonts.poppins(
                        color: Colors.redAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      " " + "currency".tr(),
                      style: GoogleFonts.cairo(
                        color: Colors.redAccent.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
                "grand_total".tr(),
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
                      "currency".tr(),
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
                "select_wallet".tr(),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
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
                                        Clipboard.setData(
                                          ClipboardData(
                                            text: wallet['account']!,
                                          ),
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'account_number_copied'.tr(),
                                              style: GoogleFonts.cairo(
                                                color: Colors.white,
                                                fontSize: 13,
                                              ),
                                            ),
                                            backgroundColor:
                                                Colors.green.shade700,
                                            duration: const Duration(
                                              seconds: 2,
                                            ),
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
                            isWalletSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: isWalletSelected
                                ? const Color(0xFFE58B29)
                                : Colors.white54,
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
                      "close".tr(),
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
    final bool isButtonDisabled =
        _isLoadingFee || _feeErrorMessage != null || cart.items.isEmpty;

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
                    "edit_cart".tr(),
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
              onTap: isButtonDisabled || context.read<OrderProvider>().isLoading
                  ? null
                  : () async {
                      if (_selectedPaymentMethod == 'bank_transfer') {
                        if (_receiptController.text.isEmpty &&
                            _receiptImage == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'receipt_validation_error'.tr(),
                                style: GoogleFonts.cairo(color: Colors.white),
                              ),
                              backgroundColor: Colors.red.shade700,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          return;
                        }
                      }

                      if (_isScheduled && _scheduledDateTime == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'please_select_schedule_time'.tr(),
                              style: GoogleFonts.cairo(color: Colors.white),
                            ),
                            backgroundColor: Colors.red.shade700,
                            duration: const Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      final prefs = await SharedPreferences.getInstance();
                      double customerLat =
                          prefs.getDouble('saved_lat') ??
                          prefs.getDouble('user_lat') ??
                          0.0;
                      double customerLng =
                          prefs.getDouble('saved_lng') ??
                          prefs.getDouble('user_lng') ??
                          0.0;

                      String restaurantId = cart.items.isNotEmpty
                          ? cart.items.first.restaurantId
                          : '';
                      List<Map<String, dynamic>> itemsPayload = cart.items
                          .map((item) {
                            final map = <String, dynamic>{
                              'quantity': item.quantity,
                              'price': item.price,
                            };
                            if (item.type == 'combo_offer' || item.offerId != null) {
                              final rawOfferId = item.offerId ?? item.id;
                              map['offer_id'] = int.tryParse(rawOfferId) ?? rawOfferId;
                            } else {
                              final rawMealId = item.mealId.isNotEmpty ? item.mealId : item.id;
                              map['meal_id'] = int.tryParse(rawMealId) ?? rawMealId;
                            }
                            return map;
                          })
                          .toList();

                      final orderProv = context.read<OrderProvider>();
                      final (
                        success,
                        errorMsg,
                        orderData,
                      ) = await orderProv.placeOrder(
                        scheduledAt: _isScheduled ? _scheduledDateTime : null,
                        paymentMethod: _selectedPaymentMethod,
                        receiptNumber: _receiptController.text.isNotEmpty
                            ? _receiptController.text
                            : null,
                        receiptImage: _receiptImage,
                        deliveryFee: deliveryFee,
                        restaurantId: restaurantId,
                        items: itemsPayload,
                        customerLat: customerLat,
                        customerLng: customerLng,
                        couponCode: cart.appliedCouponCode,
                      );

                      if (!context.mounted) return;

                      if (success) {
                        // Extract required fields before clearing cart!
                        final double subtotal = cart.totalPrice;
                        final double discount = cart.discountAmount;
                        final double grandTotal = subtotal + deliveryFee - discount;
                        final String? couponCode = cart.appliedCouponCode;
                        final String restName = cart.items.isNotEmpty
                            ? cart.items.first.restaurantName
                            : '';
                        final String restAddress = cart.items.isNotEmpty
                            ? cart.items.first.restaurantAddress
                            : '';

                        cart.clearCart();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _isScheduled
                                  ? 'order_scheduled_success'.tr()
                                  : 'order_confirmed_success'.tr(),
                              style: GoogleFonts.cairo(color: Colors.white),
                            ),
                            backgroundColor: Colors.green.shade700,
                            duration: const Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );

                        if (_isScheduled) {
                          context.go('/home');
                        } else {
                          // Merge backend orderData with local checkout state
                          Map<String, dynamic> finalOrderData =
                              Map<String, dynamic>.from(
                                orderData ?? <String, dynamic>{},
                              );
                          finalOrderData['delivery_fee'] = deliveryFee;
                          finalOrderData['subtotal'] = subtotal;
                          if (discount > 0) {
                            finalOrderData['discount'] = discount;
                          }
                          if (couponCode != null) {
                            finalOrderData['coupon_code'] = couponCode;
                          }
                          finalOrderData['total'] = grandTotal;
                          finalOrderData['restaurant'] = {
                            'name': restName,
                            'address': restAddress,
                          };

                          context.go('/order-status', extra: finalOrderData);
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              errorMsg ??
                                  (_isScheduled
                                      ? 'order_schedule_error'.tr()
                                      : 'order_confirm_error'.tr()),
                              style: GoogleFonts.cairo(color: Colors.white),
                            ),
                            backgroundColor: Colors.red.shade700,
                            duration: const Duration(seconds: 4),
                            behavior: _isScheduled
                                ? SnackBarBehavior.floating
                                : SnackBarBehavior.fixed,
                          ),
                        );
                      }
                    },
              child: Consumer<OrderProvider>(
                builder: (context, orderProv, _) {
                  return Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: isButtonDisabled || orderProv.isLoading
                          ? Colors.grey.shade700
                          : const Color(0xFFD32F2F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: (_isLoadingFee || orderProv.isLoading)
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isScheduled
                                  ? "confirm_scheduled_order".tr()
                                  : "execute_order".tr(),
                              style: GoogleFonts.cairo(
                                color: isButtonDisabled
                                    ? Colors.white38
                                    : Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A34),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "schedule_delivery".tr(),
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _showSchedulingBottomSheet(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              decoration: BoxDecoration(
                color: _isScheduled
                    ? const Color(0xFFED922A).withOpacity(0.1)
                    : const Color(0xFF2A2640).withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isScheduled
                      ? const Color(0xFFED922A).withOpacity(0.4)
                      : Colors.white.withOpacity(0.05),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: _isScheduled
                        ? const Color(0xFFED922A)
                        : Colors.white54,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isScheduled && _scheduledDateTime != null
                          ? 'scheduled_for'.tr(
                              namedArgs: {
                                'datetime': DateFormat(
                                  'yyyy/MM/dd – hh:mm a',
                                  'ar',
                                ).format(_scheduledDateTime!),
                              },
                            )
                          : 'schedule_for_later'.tr(),
                      style: GoogleFonts.cairo(
                        color: _isScheduled
                            ? const Color(0xFFED922A)
                            : Colors.white54,
                        fontSize: 13,
                        fontWeight: _isScheduled
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (_isScheduled)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isScheduled = false;
                          _scheduledDateTime = null;
                        });
                      },
                      child: const Icon(
                        Icons.close,
                        color: Colors.white54,
                        size: 20,
                      ),
                    )
                  else
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white30,
                      size: 16,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSchedulingBottomSheet() {
    DateTime selectedDate =
        _scheduledDateTime ?? DateTime.now().add(const Duration(hours: 1));
    TimeOfDay selectedTime = _scheduledDateTime != null
        ? TimeOfDay.fromDateTime(_scheduledDateTime!)
        : TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final combinedDateTime = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              selectedTime.hour,
              selectedTime.minute,
            );

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1A34),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "choose_delivery_time".tr(),
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 25),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 30),
                          ),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Color(0xFFED922A),
                                  onPrimary: Colors.white,
                                  surface: Color(0xFF1E1A34),
                                  onSurface: Colors.white,
                                ),
                                dialogBackgroundColor: const Color(0xFF140C36),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setSheetState(() => selectedDate = picked);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2640).withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Color(0xFFED922A),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat(
                                'yyyy/MM/dd',
                                'ar',
                              ).format(selectedDate),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white30,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Color(0xFFED922A),
                                  onPrimary: Colors.white,
                                  surface: Color(0xFF1E1A34),
                                  onSurface: Colors.white,
                                ),
                                dialogBackgroundColor: const Color(0xFF140C36),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setSheetState(() => selectedTime = picked);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2640).withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Color(0xFFED922A),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              selectedTime.format(context),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white30,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFED922A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFED922A).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFFED922A),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'delivery_scheduled_info'.tr(
                                namedArgs: {
                                  'date': DateFormat(
                                    'yyyy/MM/dd',
                                    'ar',
                                  ).format(selectedDate),
                                  'time': selectedTime.format(context),
                                },
                              ),
                              style: GoogleFonts.cairo(
                                color: const Color(0xFFED922A),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isScheduled = true;
                            _scheduledDateTime = combinedDateTime;
                          });
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFED922A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          "confirm_schedule".tr(),
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
