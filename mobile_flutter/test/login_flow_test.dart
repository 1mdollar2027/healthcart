import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:healthcart/features/auth/screens/login_screen.dart';
import 'package:healthcart/core/services/auth_provider.dart';
import 'package:healthcart/core/theme.dart';

void main() {
  testWidgets('LoginScreen UI contains Phone Input and Submit Button', (WidgetTester tester) async {
    // Wrap in necessary providers for local UI test
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: MaterialApp(
          theme: HealthCartTheme.lightTheme,
          home: const LoginScreen(),
        ),
      ),
    );

    // Initial pump and settle
    await tester.pumpAndSettle();

    // Verify Title and Subtitle exist
    expect(find.text('HealthCart'), findsOneWidget);
    expect(find.text('India\'s Telemedicine Super-App'), findsOneWidget);

    // Verify Phone input field exists
    expect(find.byType(TextFormField), findsOneWidget);
    
    // Verify Request OTP button exists
    expect(find.text('Request OTP'), findsOneWidget);

    // Enter a valid phone number
    await tester.enterText(find.byType(TextFormField), '9876543210');
    await tester.pump(); // trigger UI updates

    // Tap Request OTP (Since this is a mocked UI test without real Supabase, it will hit a loading state or fail gracefully in auth provider provider catch block)
    await tester.tap(find.text('Request OTP'));
    await tester.pump(); 
    
    // We just verify it doesn't crash on tap.
    expect(tester.takeException(), isNull);
  });
}
