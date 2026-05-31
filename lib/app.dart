import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_screen.dart';
import 'screens/login_screen.dart';
import 'screens/permission_gate.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color ecoGreen = Color(0xFF2E7D32);
  static const Color ecoBackground = Color(0xFFF1F8E9);

  // grade color
  static Color gradeColor(String grade) {
    switch (grade.toLowerCase()) {
      case 'a':
        return const Color(0xFF1E8E3E);
      case 'b':
        return const Color(0xFF7CB342);
      case 'c':
        return const Color(0xFFF9A825);
      case 'd':
        return const Color(0xFFF57C00);
      case 'e':
      case 'f':
        return const Color(0xFFD32F2F);
      default:
        return Colors.grey;
    }
  }

  static String gradeLabel(String grade) {
    const letters = {'a', 'b', 'c', 'd', 'e', 'f'};
    final g = grade.toLowerCase();
    return letters.contains(g) ? g.toUpperCase() : 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoScan Madrid',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: ecoGreen),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.data != null) {
              // logged in
              return const PermissionGate(child: MainScreen());
            }
            return const LoginScreen(); // Usuario no está logueado
          }
          return const Center(
            child: CircularProgressIndicator(),
          ); // Esperando conexión
        },
      ),
    );
  }
}
