import 'package:customer_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/api/dio_client.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'core/routing/app_router.dart';
import 'providers/cart_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/restaurant_provider.dart';
import 'providers/order_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/notifications_provider.dart';
import 'core/services/firebase_messaging_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final fcmService = FirebaseMessagingService();
  await fcmService.initNotifications();

  final prefs = await SharedPreferences.getInstance();
  final dioClient = DioClient();
  final authRepository = AuthRepository(dioClient, prefs);

  runApp(
    ProviderScope(
      child: MyApp(
        authRepository: authRepository,
        dioClient: dioClient, // 👉 تم تمرير dioClient هنا
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;
  final DioClient dioClient; // 👉 تم تعريف المتغير هنا

  const MyApp({
    super.key,
    required this.authRepository,
    required this.dioClient, // 👉 تمت إضافته للمُشيد
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 👉 هذا هو السطر السحري الذي سيحل مشكلة الشاشة الحمراء
        Provider<DioClient>.value(value: dioClient),
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(authRepository)..add(AppStarted()),
        ),
        ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
        ChangeNotifierProvider<FavoritesProvider>(
          create: (_) => FavoritesProvider(),
        ),
        ChangeNotifierProvider<ScheduleProvider>(
          create: (_) => ScheduleProvider(),
        ),

        ChangeNotifierProvider<OrderProvider>(create: (_) => OrderProvider()),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<NotificationsProvider>(
          create: (_) => NotificationsProvider(),
        ),
      ],
      child: Builder(
        builder: (context) {
          final themeMode = context.watch<ThemeProvider>().themeMode;
          return MaterialApp.router(
            title: 'FastGrab',
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            theme: ThemeData(
              brightness: Brightness.light,
              primarySwatch: Colors.blue,
              fontFamily: 'Cairo',
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.blue,
              fontFamily: 'Cairo',
            ),
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
