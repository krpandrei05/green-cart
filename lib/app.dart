import 'package:flutter/material.dart';
import 'main_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color ecoGreen = Color(0xFF2E7D32);
  static const Color ecoBackground = Color(0xFFF1F8E9);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoScan Madrid',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: ecoGreen),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}
