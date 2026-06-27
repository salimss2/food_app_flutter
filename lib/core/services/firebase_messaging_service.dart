import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../api/dio_client.dart';
import '../api/endpoints.dart';
import '../routing/app_router.dart';
import '../../providers/order_provider.dart';
import '../../providers/notifications_provider.dart';

// Required top-level function for background message handling
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
  if (message.notification != null) {
    debugPrint('Message also contained a notification: ${message.notification}');
  }
}

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    // 1. Request notification permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // Setup local notifications for Android and iOS
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInitSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _localNotificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle foreground local notification tap
        debugPrint('Local notification tapped: ${response.payload}');
        if (response.payload != null) {
          // Route based on tap from foreground local notification
          AppRouter.router.push('/notifications');
        }
      },
    );

    // Create an Android Notification Channel for heads-up notifications
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Ensure FCM displays heads up notifications on iOS
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Fetch the FCM token
    try {
      String? token = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $token');
      if (token != null) {
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }

    // 3. Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // Show local notification using flutter_local_notifications
      if (notification != null && android != null) {
        _localNotificationsPlugin.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: android.smallIcon ?? '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          payload: message.data.toString(),
        );
      }

      // Get context from global router
      final context =
          AppRouter.router.routerDelegate.navigatorKey.currentContext;

      if (context != null) {
        // Trigger Provider to add notification to UI real-time
        final notificationData = {
          'id': message.messageId ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          'title': message.notification?.title ?? 'إشعار',
          'body': message.notification?.body ?? '',
          'type': message.data['type'] ?? 'system',
          'created_at': DateTime.now().toIso8601String(),
          'read_at': null,
          'isRead': false,
        };
        Provider.of<NotificationsProvider>(context, listen: false)
            .addNotification(notificationData);
      }

      // 4. Trigger Order Tracking Refresh if applicable
      if (message.data.containsKey('order_id') &&
          message.data.containsKey('status')) {
        debugPrint('Order status update received, refreshing orders...');
        if (context != null) {
          Provider.of<OrderProvider>(context, listen: false).fetchOrders();
        }
      }
    });

    // 5. Listen to background messages
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 6. Handle interactions when the app is in the background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // 7. Handle interactions when the app is terminated
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // 8. Listen to token refreshes
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugPrint('FCM Token Refreshed: $newToken');
      _sendTokenToBackend(newToken);
    });
  }

  // Public method to force sync token (useful after login)
  Future<void> syncToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token during sync: $e');
    }
  }

  // Handle routing based on message payload when tapped
  void _handleMessage(RemoteMessage message) {
    final data = message.data;
    if (data.containsKey('order_id') && data.containsKey('status')) {
      final status = data['status'];
      if (status == 'payment_rejected' || status == 'payment_verified') {
        debugPrint(
            'Navigating to Order Details for Order ID: ${data['order_id']}');

        // Navigate directly using the global GoRouter instance
        AppRouter.router.push(
          '/order-tracking',
          extra: {'id': data['order_id'], 'status': status, ...data},
        );
      }
    } else {
      // General notification -> go to Notifications screen
      debugPrint('Navigating to Notifications screen');
      AppRouter.router.push('/notifications');
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      final dioClient = DioClient();
      final response = await dioClient.dio.post(
        Endpoints.updateFcmToken,
        data: {'fcm_token': token},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Successfully sent FCM token to backend.');
      } else {
        debugPrint(
            'Failed to send FCM token. Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending FCM token to backend: $e');
    }
  }
}
