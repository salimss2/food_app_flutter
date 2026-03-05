import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api/dio_client.dart'; 
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'core/routing/app_router.dart'; // <-- استيراد ملف الخريطة المركزي

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. تهيئة الأدوات
  final prefs = await SharedPreferences.getInstance();
  final dioClient = DioClient();
  final authRepository = AuthRepository(dioClient, prefs);

  // 2. تشغيل التطبيق
  runApp(MyApp(authRepository: authRepository));
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;

  const MyApp({super.key, required this.authRepository});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(authRepository)..add(AppStarted()),
        ),
      ],
      // التعديل الأهم: استخدام MaterialApp.router
      child: MaterialApp.router(
        title: 'FastGrab',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Cairo', // توحيد الخط
        ),
        // ربط التطبيق بملف التوجيه
        routerConfig: AppRouter.router, 
        
        // ملاحظة: تم حذف خاصية 'home:' لأن الـ router هو من يقرر شاشة البداية الآن
      ),
    );
  }
}