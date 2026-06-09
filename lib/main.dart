import 'package:flutter/material.dart';
import 'features/auth/screens/splash_screen.dart';

void main() {
  runApp(const StuffRideApp());
}

class StuffRideApp extends StatelessWidget {
  const StuffRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stuff Ride',
      home: const SplashScreen(),
    );
  }
}