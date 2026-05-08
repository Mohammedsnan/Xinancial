import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'admin/admin_orders.dart';
import 'admin/admin_products.dart';
import 'auth/auth_service.dart';
import 'customer/cart_page.dart';
import 'customer/profile_page.dart';
import 'firebase_options.dart';
import 'home_screenPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CustomerApp());
}

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TowWayShop - عميل',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Cairo',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) =>  AuthScreen(),
        '/home': (context) =>  HomeScreen(),
        '/cart': (context) => const CartScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/products': (context) => const AdminProductsPage(),
        '/orders': (context) => const AdminOrdersPage(),  // إدارة الطلبات
      },
    );
  }
}