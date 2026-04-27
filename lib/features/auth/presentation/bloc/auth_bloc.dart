import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/auth_repository.dart';
import '../../data/user_model.dart';
import '../../../../core/services/firebase_messaging_service.dart';

// --- Events ---
abstract class AuthEvent {}

class AppStarted extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested(this.email, this.password);
}

class SignUpRequested extends AuthEvent {
  final UserModel user;
  SignUpRequested(this.user);
}

class LogoutRequested extends AuthEvent {}

// --- States ---
abstract class AuthState {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final UserModel user;
  Authenticated(this.user);
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// --- Bloc ---
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc(this.authRepository) : super(AuthInitial()) {
    
    // 1. عند فتح التطبيق، نتحقق هل هو مسجل دخول مسبقاً؟
    on<AppStarted>((event, emit) {
      final user = authRepository.getCurrentUser(); // الآن لن يظهر خطأ هنا
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    });

    // 2. التسجيل الجديد
    on<SignUpRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        // تم تغيير signUp إلى register وتمرير البيانات بشكل صحيح
        final registeredUser = await authRepository.register(
          event.user.name, 
          event.user.email, 
          event.user.password
        );
        FirebaseMessagingService().syncToken();
        emit(Authenticated(registeredUser));
      } catch (e) {
        // تنظيف رسالة الخطأ القادمة من الـ Repository
        emit(AuthError(e.toString().replaceAll("Exception: ", "")));
      }
    });

    // 3. تسجيل الدخول
    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await authRepository.login(event.email, event.password);
        FirebaseMessagingService().syncToken();
        emit(Authenticated(user));
      } catch (e) {
         // تنظيف رسالة الخطأ لتبدو جميلة للمستخدم
        emit(AuthError(e.toString().replaceAll("Exception: ", "")));
      }
    });

    // 4. تسجيل الخروج
    on<LogoutRequested>((event, emit) async {
      emit(AuthLoading());
      await authRepository.logout();
      emit(Unauthenticated());
    });
  }
}