import 'package:flutter/material.dart';
import 'screens/start_screen.dart';

void main() {
  runApp(const AbqarenoApp());
}

class AbqarenoApp extends StatelessWidget {
  const AbqarenoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'عبقرينو',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF0A0F2D),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A237E),
          elevation: 0,
        ),
        fontFamily: 'Tajawal',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
        ),
      ),
      home: const StartScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}