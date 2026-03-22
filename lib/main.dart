
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/customer_home_screen.dart';
import 'screens/admin_orders_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shoe Shop',
      // Theme Tone Blue - White
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          elevation: 0,
          centerTitle: true,
        ),
      ),


      home: const CustomerHomeScreen(),

      // Định nghĩa các tuyến đường (routes) để dễ dàng chuyển màn hình
      routes: {
        '/login': (context) => const LoginScreen(),
        '/admin': (context) => AdminDashboardScreen(),
        '/home': (context) => const CustomerHomeScreen(),
        '/admin_orders': (context) => const AdminOrdersScreen(),
      },
    );
  }
}