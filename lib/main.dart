import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/api/dio_client.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'core/routing/app_router.dart';
import 'providers/cart_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/schedule_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);

  final prefs = await SharedPreferences.getInstance();
  final dioClient = DioClient();
  final authRepository = AuthRepository(dioClient, prefs);

  runApp(MyApp(authRepository: authRepository));
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;

  const MyApp({super.key, required this.authRepository});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
      ],
      child: MaterialApp.router(
        title: 'FastGrab',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Cairo'),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
