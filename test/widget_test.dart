import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:customer_app/main.dart';
import 'package:customer_app/core/api/dio_client.dart';
import 'package:customer_app/features/auth/data/auth_repository.dart';

void main() {
  testWidgets('App splash screen smoke test', (WidgetTester tester) async {
    // 1. Setup mock dependencies
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final dioClient = DioClient();
    final authRepository = AuthRepository(dioClient, prefs);

    // 2. Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(authRepository: authRepository));

    // 3. Verify that the app starts
    expect(find.byType(MyApp), findsOneWidget);
  });
}
