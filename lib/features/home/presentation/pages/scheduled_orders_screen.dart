import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/widgets/custom_background.dart';
import '../../../../providers/schedule_provider.dart';

class ScheduledOrdersScreen extends StatefulWidget {
  const ScheduledOrdersScreen({super.key});

  @override
  State<ScheduledOrdersScreen> createState() => _ScheduledOrdersScreenState();
}

class _ScheduledOrdersScreenState extends State<ScheduledOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleProvider>().fetchScheduledOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomBackground(
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: Consumer<ScheduleProvider>(
                    builder: (context, scheduleProv, child) {
                      if (scheduleProv.isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(color: Color(0xFFED922A)),
                        );
                      }
                      
                      final orders = scheduleProv.scheduledOrders;
                      if (orders.isEmpty) {
                        return _buildEmptyState();
                      }
                      
                      return ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        itemCount: orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 15),
                        itemBuilder: (context, index) {
                          return _buildScheduledOrderCard(
                            context,
                            orders[index],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
            "الطلبات المجدولة",
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule, color: Colors.white.withOpacity(0.15), size: 90),
          const SizedBox(height: 20),
          Text(
            "لا توجد طلبات مجدولة",
            style: GoogleFonts.cairo(
              color: Colors.white54,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledOrderCard(
    BuildContext context,
    Map<String, dynamic> order,
  ) {
    final scheduledAtStr = order['scheduled_at']?.toString() ?? '';
    DateTime scheduledDate;
    try {
      scheduledDate = DateTime.parse(scheduledAtStr);
    } catch (e) {
      scheduledDate = DateTime.now();
    }
    final dateFormat = DateFormat('yyyy/MM/dd', 'en'); 
    final timeFormat = DateFormat('hh:mm a', 'ar');
    final formattedDate = dateFormat.format(scheduledDate);
    final formattedTime = timeFormat.format(scheduledDate);

    final orderNumber = order['order_number']?.toString() ?? '';
    final itemsCount = order['items_count']?.toString() ?? '0';
    final totalAmount = order['total_amount']?.toString() ?? '0';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A34),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header Row ---
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFED922A).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.schedule,
                  color: Color(0xFFED922A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "طلب #$orderNumber",
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "$itemsCount عناصر",
                      style: GoogleFonts.cairo(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFED922A).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "مجدول",
                  style: GoogleFonts.cairo(
                    color: const Color(0xFFED922A),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // --- Date/Time Info ---
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2640).withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Colors.white54,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  formattedDate,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 20),
                const Icon(Icons.access_time, color: Colors.white54, size: 18),
                const SizedBox(width: 10),
                Text(
                  formattedTime,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // --- Total Price ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "المجموع الكلي",
                style: GoogleFonts.cairo(color: Colors.white54, fontSize: 13),
              ),
              Text(
                "$totalAmount ر.ي",
                style: GoogleFonts.poppins(
                  color: const Color(0xFFED922A),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Divider(color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 5),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _showOrderDetailsBottomSheet(context, order),
              icon: const Icon(Icons.remove_red_eye_outlined, color: Color(0xFFED922A), size: 18),
              label: Text(
                'تفاصيل الطلب',
                style: GoogleFonts.cairo(
                  color: const Color(0xFFED922A),
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: const Color(0xFFED922A).withOpacity(0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetailsBottomSheet(BuildContext context, Map<String, dynamic> order) {
    final scheduledAtStr = order['scheduled_at']?.toString() ?? '';
    DateTime scheduledDate;
    try {
      scheduledDate = DateTime.parse(scheduledAtStr);
    } catch (e) {
      scheduledDate = DateTime.now();
    }
    final timeFormat = DateFormat('yyyy/MM/dd - hh:mm a', 'ar');
    final formattedTime = timeFormat.format(scheduledDate);
    
    final orderNumber = order['order_number']?.toString() ?? '';
    final itemsCount = order['items_count']?.toString() ?? '0';
    final totalAmount = order['total_amount']?.toString() ?? '0';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1A34),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Order Number and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "طلب #$orderNumber",
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFED922A).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "مجدول",
                        style: GoogleFonts.cairo(
                          color: const Color(0xFFED922A),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Brief Summary
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2640).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("الوقت المجدول", style: GoogleFonts.cairo(color: Colors.white54)),
                          Text(formattedTime, style: GoogleFonts.poppins(color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("عدد العناصر", style: GoogleFonts.cairo(color: Colors.white54)),
                          Text("$itemsCount", style: GoogleFonts.poppins(color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("المجموع الكلي", style: GoogleFonts.cairo(color: Colors.white54)),
                          Text("$totalAmount ر.ي", style: GoogleFonts.poppins(color: const Color(0xFFED922A), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Implement edit time
                          print("Edit Time tapped");
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: Text(
                          "تعديل الموعد",
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFED922A),
                          side: const BorderSide(color: Color(0xFFED922A)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final shouldCancel = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => Directionality(
                              textDirection: TextDirection.rtl,
                              child: AlertDialog(
                                backgroundColor: const Color(0xFF1E1A34),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: Text(
                                  "تأكيد الإلغاء",
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                content: Text(
                                  "هل أنت متأكد من إلغاء الطلب؟",
                                  style: GoogleFonts.cairo(color: Colors.white54, fontSize: 14),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text("تراجع", style: GoogleFonts.cairo(color: Colors.white54)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFD32F2F),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text("نعم، إلغاء", style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          );

                          if (shouldCancel == true && context.mounted) {
                            final orderId = order['id'];
                            final int parsedId = orderId is int ? orderId : int.tryParse(orderId.toString()) ?? 0;
                            
                            final success = await context.read<ScheduleProvider>().cancelOrder(parsedId);
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'تم إلغاء الطلب بنجاح',
                                    style: GoogleFonts.cairo(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.green.shade700,
                                ),
                              );
                              Navigator.pop(context); // Close the bottom sheet
                            }
                          }
                        },
                        icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.white),
                        label: Text(
                          "إلغاء الطلب",
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}
