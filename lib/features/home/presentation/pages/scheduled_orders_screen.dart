import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/widgets/custom_background.dart';
import '../../../../providers/schedule_provider.dart';

class ScheduledOrdersScreen extends StatelessWidget {
  const ScheduledOrdersScreen({super.key});

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
                      final orders = scheduleProv.orders;
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
                            scheduleProv,
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
            "لا توجد طلبات مجدولة حالياً 🕰️",
            style: GoogleFonts.cairo(
              color: Colors.white54,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "يمكنك جدولة طلبك من شاشة الدفع",
            style: GoogleFonts.cairo(color: Colors.white30, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledOrderCard(
    BuildContext context,
    ScheduledOrder order,
    ScheduleProvider scheduleProv,
  ) {
    final dateFormat = DateFormat('yyyy/MM/dd', 'ar');
    final timeFormat = DateFormat('hh:mm a', 'ar');
    final formattedDate = dateFormat.format(order.scheduledDateTime);
    final formattedTime = timeFormat.format(order.scheduledDateTime);

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
                      "طلب #${order.id.substring(order.id.length - 6)}",
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${order.items.length} عناصر",
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
                "${order.totalPrice.toStringAsFixed(0)} ر.ي",
                style: GoogleFonts.poppins(
                  color: const Color(0xFFED922A),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // --- Action Buttons ---
          Row(
            children: [
              // Edit Button
              Expanded(
                child: InkWell(
                  onTap: () =>
                      _showEditScheduleSheet(context, order, scheduleProv),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2640),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFED922A).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.edit,
                          color: Color(0xFFED922A),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "تعديل الموعد",
                          style: GoogleFonts.cairo(
                            color: const Color(0xFFED922A),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Cancel Button
              Expanded(
                child: InkWell(
                  onTap: () =>
                      _showCancelConfirmation(context, order, scheduleProv),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFD32F2F).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.cancel_outlined,
                          color: Color(0xFFD32F2F),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "إلغاء الطلب",
                          style: GoogleFonts.cairo(
                            color: const Color(0xFFD32F2F),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditScheduleSheet(
    BuildContext context,
    ScheduledOrder order,
    ScheduleProvider scheduleProv,
  ) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: order.scheduledDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
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

    if (pickedDate != null && context.mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(order.scheduledDateTime),
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

      if (pickedTime != null && context.mounted) {
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        scheduleProv.updateSchedule(order.id, newDateTime);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تحديث موعد التوصيل بنجاح ✅',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showCancelConfirmation(
    BuildContext context,
    ScheduledOrder order,
    ScheduleProvider scheduleProv,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFF1E1A34),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              "إلغاء الطلب المجدول",
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              "هل أنت متأكد من إلغاء هذا الطلب المجدول؟ لا يمكن التراجع عن هذا الإجراء.",
              style: GoogleFonts.cairo(color: Colors.white54, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  "تراجع",
                  style: GoogleFonts.cairo(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  scheduleProv.cancelOrder(order.id);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'تم إلغاء الطلب المجدول بنجاح',
                        style: GoogleFonts.cairo(color: Colors.white),
                      ),
                      backgroundColor: Colors.red.shade700,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "نعم، إلغاء",
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
