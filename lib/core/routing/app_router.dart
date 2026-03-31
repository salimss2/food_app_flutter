import 'package:customer_app/features/home/presentation/widgets/orders_screen.dart';
import 'package:go_router/go_router.dart';
// --- استيراد شاشات البداية ---
import '../../features/startup/presentation/pages/animated_splash_screen.dart';
import '../../features/startup/presentation/pages/splash_screen.dart';
import '../../features/startup/presentation/pages/onboarding_screen.dart';
import '../../features/startup/presentation/pages/location_access_screen.dart';

// --- استيراد شاشة الخريطة ---
import '../../features/settings/presentation/pages/map_picker_screen.dart';

// --- استيراد شاشات المصادقة ---
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/pages/signup_screen.dart';
import '../../features/auth/presentation/pages/forgot_password_screen.dart';
import '../../features/auth/presentation/pages/verification_screen.dart';

// --- استيراد الشاشات الرئيسية ---
import '../../features/home/presentation/pages/home_screen.dart';
import '../../features/home/presentation/pages/restaurants_screen.dart';
import '../../features/home/presentation/pages/meals_list_screen.dart'; // تأكد من صحة المسار
import '../../features/home/presentation/pages/meal_detail_screen.dart'; // تأكد من صحة المسار
import '../../features/home/presentation/pages/search_screen.dart'; // تأكد من دقة المسار

// --- استيراد شاشات الإعدادات والبروفايل ---
import '../../features/settings/presentation/pages/settings_screen.dart';
import '../../features/settings/presentation/pages/profile_screen.dart';
import '../../features/settings/presentation/pages/privacy_policy_screen.dart';
import '../../features/settings/presentation/pages/about_app_screen.dart';

import '../../features/home/presentation/pages/restaurant_detail_screen.dart';
import '../../features/home/presentation/pages/cart_screen.dart';
import '../../features/home/presentation/pages/checkout_screen.dart';
import '../../features/home/presentation/pages/order_status_screen.dart';
import '../../features/home/presentation/pages/order_tracking_screen.dart';
import '../../features/home/presentation/pages/rate_order_screen.dart';
import '../../features/favorites/presentation/pages/favorites_screen.dart';

abstract class AppRouter {
  static final router = GoRouter(
    // نقطة البداية عند تشغيل التطبيق (ستكون شاشة الأنيميشن)
    initialLocation: '/animated-splash',

    routes: [
      // 1. مسارات البداية
      GoRoute(
        path: '/animated-splash',
        builder: (context, state) => const AnimatedSplashScreen(),
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/location-access',
        builder: (context, state) => const LocationAccessScreen(),
      ),
      GoRoute(
        path: '/map-picker',
        builder: (context, state) => const MapPickerScreen(),
      ),

      // 2. مسارات المصادقة
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verification',
        builder: (context, state) => const VerificationScreen(),
      ),

      // 3. المسارات الرئيسية
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/restaurants',
        builder: (context, state) => const RestaurantsScreen(),
      ),
      GoRoute(
        path: '/meals-list',
        builder: (context, state) => const MealsListScreen(),
      ),
      GoRoute(
        path: '/meal-detail',
        builder: (context, state) {
          final mealData = state.extra as Map<String, dynamic>? ?? {};
          return MealDetailScreen(mealData: mealData);
        },
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),

      // 4. مسارات الإعدادات
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/about-app',
        builder: (context, state) => const AboutAppScreen(),
      ),
      GoRoute(
        path: '/restaurant-detail',
        builder: (context, state) {
          final restaurantData = state.extra as Map<String, dynamic>? ?? {};
          return RestaurantDetailScreen(restaurantData: restaurantData);
        },
      ),
      GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/order-status',
        builder: (context, state) {
          final orderData = state.extra as Map<String, dynamic>? ?? {};
          return OrderStatusScreen(orderData: orderData);
        },
      ),
      GoRoute(
        path: '/order-tracking',
        builder: (context, state) {
          final orderData = state.extra as Map<String, dynamic>? ?? {};
          return OrderTrackingScreen(orderData: orderData);
        },
      ),
      GoRoute(
        path: '/rate-order',
        builder: (context, state) => const RateOrderScreen(),
      ),
    ],
  );
}
