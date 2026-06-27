import 'package:flutter/foundation.dart';
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

// 🟢 1. أضفنا حدث تسجيل الدخول بجوجل هنا ليتعرف عليه الـ VS Code
class GoogleLoginSuccessEvent extends AuthEvent {
  final dynamic userData;
  final String token;
  GoogleLoginSuccessEvent(this.userData, this.token);
}

class ProfileUpdatedEvent extends AuthEvent {
  final UserModel user;
  ProfileUpdatedEvent(this.user);
}

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
      final user = authRepository.getCurrentUser();
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
        final registeredUser = await authRepository.register(
          event.user.name,
          event.user.email,
          event.user.password,
        );
        FirebaseMessagingService().syncToken();
        emit(Authenticated(registeredUser));
      } catch (e) {
        emit(AuthError(e.toString().replaceAll("Exception: ", "")));
      }
    });

    // 3. تسجيل الدخول العادي
    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await authRepository.login(event.email, event.password);
        FirebaseMessagingService().syncToken();
        emit(Authenticated(user));
      } catch (e) {
        emit(AuthError(e.toString().replaceAll("Exception: ", "")));
      }
    });

    // 🟢 4. تسجيل الدخول بجوجل
    on<GoogleLoginSuccessEvent>((event, emit) async {
      try {
        // 1. تحويل البيانات القادمة من السيرفر إلى UserModel
        final UserModel user = UserModel.fromJson(
          event.userData is Map<String, dynamic>
              ? event.userData as Map<String, dynamic>
              : Map<String, dynamic>.from(event.userData as Map),
        );

        // 2. حفظ التوكن والبيانات بنفس المفاتيح التي يقرأها getCurrentUser
        //    ('auth_token' + 'user_data' + 'is_logged_in')
        await authRepository.saveGoogleAuthData(user, event.token);

        // 3. إخبار التطبيق بحالة المصادقة فوراً
        FirebaseMessagingService().syncToken();
        emit(Authenticated(user));
      } catch (e) {
        debugPrint('❌ [Google Auth] Error parsing user: $e');
        emit(AuthError('حدث خطأ أثناء قراءة بيانات المستخدم'));
      }
    });

    // 5. تسجيل الخروج
    on<LogoutRequested>((event, emit) async {
      emit(AuthLoading());
      await authRepository.logout();
      emit(Unauthenticated());
    });

    on<ProfileUpdatedEvent>((event, emit) {
      emit(Authenticated(event.user));
    });
  }
}
