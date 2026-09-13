import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/widgets/custom_background.dart';
import '../../../../providers/notifications_provider.dart';
import '../widgets/ticket_response_bottom_sheet.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationsProvider>();
    final notifications = provider.notifications;
    final isLoading = provider.isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomBackground(
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(context, isDark),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : (notifications.isEmpty
                          ? _buildEmptyState(isDark)
                          : ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 15,
                              ),
                              itemCount: notifications.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 15),
                              itemBuilder: (context, index) {
                                return _buildNotificationCard(
                                    notifications[index], isDark);
                              },
                            )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
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
                    color: isDark ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: isDark ? Colors.white : Colors.black87,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Text(
            "الإشعارات",
            style: GoogleFonts.cairo(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 40), // Placeholder to balance AppBar
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2),
            size: 80,
          ),
          const SizedBox(height: 20),
          Text(
            "لا توجد إشعارات حالياً",
            style: GoogleFonts.cairo(
              color: isDark ? Colors.white54 : Colors.black54,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, bool isDark) {
    final bool isRead = notification['isRead'] ?? (notification['read_at'] != null);
    
    // Parse inner data wrapper
    final payload = notification['data'] is Map ? notification['data'] : {};
    
    // Determine type from inner status or outer type
    final String type = payload['status'] ?? notification['type'] ?? 'system';
    final String title = payload['title'] ?? notification['title'] ?? 'إشعار';
    final String body = payload['message'] ?? notification['body'] ?? payload['body'] ?? '';
    final String rawTime = notification['time'] ?? notification['created_at'] ?? '';
    
    String formattedTime = rawTime;
    if (rawTime.isNotEmpty) {
      try {
        final parsedDate = DateTime.parse(rawTime).toLocal();
        formattedTime = DateFormat('yyyy-MM-dd hh:mm a', 'ar').format(parsedDate);
      } catch (_) {}
    }

    IconData iconData;
    Color iconColor;
    Color? customCardBgColor;
    Color? customCardBorderColor;

    switch (type) {
      case 'order':
        iconData = Icons.fastfood;
        iconColor = const Color(0xFF0F55E8); // Blue
        break;
      case 'offer':
        iconData = Icons.local_offer;
        iconColor = const Color(0xFFFF416C); // Pink/Red
        break;
      case 'rejection':
        iconData = Icons.error_outline;
        iconColor = Colors.redAccent;
        customCardBgColor = isDark 
            ? Colors.red.withOpacity(0.15) 
            : Colors.red.withOpacity(0.05);
        customCardBorderColor = Colors.red.withOpacity(0.3);
        break;
      case 'verified':
      case 'accepted':
        iconData = Icons.check_circle_outline;
        iconColor = Colors.green;
        customCardBgColor = isDark 
            ? Colors.green.withOpacity(0.15) 
            : Colors.green.withOpacity(0.05);
        customCardBorderColor = Colors.green.withOpacity(0.3);
        break;
      case 'ticket_response':
        iconData = Icons.support_agent_outlined;
        iconColor = const Color(0xFF9C27B0); // Purple
        customCardBgColor = isDark 
            ? const Color(0xFF9C27B0).withOpacity(0.15) 
            : const Color(0xFF9C27B0).withOpacity(0.05);
        customCardBorderColor = const Color(0xFF9C27B0).withOpacity(0.3);
        break;
      case 'system':
      default:
        iconData = Icons.notifications_active_outlined;
        iconColor = const Color(0xFFE58B29); // Orange
        break;
    }

    final defaultBgColor = isRead
        ? (isDark ? const Color(0xFF1E1A34) : Colors.white.withOpacity(0.8))
        : (isDark ? const Color(0xFF2A2640).withOpacity(0.8) : Colors.white);
        
    final defaultBorderColor = isRead
        ? (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))
        : (isDark ? const Color(0xFFE58B29).withOpacity(0.3) : const Color(0xFFE58B29).withOpacity(0.3));

    return InkWell(
      onTap: () {
        if (!isRead) {
          context.read<NotificationsProvider>().markAsRead(notification['id'].toString());
        }
        
        final String tapType = (payload['type']?.toString() ?? notification['type']?.toString() ?? '').toLowerCase();
        
        if (tapType.contains('ticket') || tapType.contains('support') || tapType.contains('reply') || tapType.contains('response')) {
          final String ticketCode = payload['ticket_code']?.toString() ?? 'N/A';
          final String adminResponse = payload['admin_response']?.toString() 
                                    ?? payload['message']?.toString() 
                                    ?? body;
          final String status = payload['status']?.toString() ?? 'تم الرد';
          
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => TicketDetailsBottomSheet(
              ticketCode: ticketCode,
              status: status,
              adminResponse: adminResponse,
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: customCardBgColor ?? defaultBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
          color: customCardBorderColor ?? defaultBorderColor,
        ),
        boxShadow: isRead && customCardBgColor == null
            ? []
            : [
                BoxShadow(
                  color: customCardBgColor != null 
                      ? Colors.red.withOpacity(0.05) 
                      : const Color(0xFFE58B29).withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Leading Icon ---
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: iconColor, size: 24),
          ),
          const SizedBox(width: 15),

          // --- Content ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.cairo(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 15,
                          fontWeight:
                              isRead ? FontWeight.w600 : FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: customCardBgColor != null ? Colors.redAccent : const Color(0xFFE58B29),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: GoogleFonts.cairo(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  formattedTime,
                  style: GoogleFonts.cairo(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}

class TicketDetailsBottomSheet extends StatelessWidget {
  final String ticketCode;
  final String adminResponse;
  final String status;

  const TicketDetailsBottomSheet({
    super.key,
    required this.ticketCode,
    required this.adminResponse,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1A34).withOpacity(0.85),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "تفاصيل الرد على التذكرة",
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "#$ticketCode",
                            style: GoogleFonts.cairo(
                              color: Colors.white54,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.cairo(
                          color: Colors.greenAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 250),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      adminResponse,
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFED922A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "إغلاق",
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
