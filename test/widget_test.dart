import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_project/screens/login_screen.dart';

void main() {
  // Pumping the whole MyApp would hit FirebaseAuth.instance (auth gate) and
  // requires Firebase.initializeApp, so we test LoginScreen in isolation —
  // its build() touches no Firebase API (only the buttons do).
  testWidgets('LoginScreen renders fields and toggles Sign in <-> Register',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    // Default state: sign-in.
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('No account? Register'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));

    // Toggle to register mode.
    await tester.tap(find.text('No account? Register'));
    await tester.pump();

    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Already have an account? Sign in'), findsOneWidget);
  });
}
