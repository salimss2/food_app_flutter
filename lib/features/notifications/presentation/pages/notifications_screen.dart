import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/custom_background.dart';
import '../../../../providers/notifications_provider.dart';

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
    final String type = notification['type'] ?? 'system';
    final String title = notification['title'] ?? 'إشعار';
    final String body = notification['body'] ?? '';
    final String time = notification['time'] ?? notification['created_at'] ?? '';

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
      case 'system':
      default:
        iconData = Icons.notifications;
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
                  time,
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
