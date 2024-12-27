
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:inventoryapp/screens/dashboard_screen.dart';
import 'package:inventoryapp/screens/login_screen.dart';
import 'package:inventoryapp/screens/register_screen.dart';
import 'firebase_options.dart';

void main() async {
  // Pastikan binding sudah diinisialisasi
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase
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
      initialRoute: '/', // Halaman awal yang akan ditampilkan
      routes: {
        '/': (context) => LoginScreen(), // Halaman login
        '/register': (context) => RegisterScreen(), // Halaman registrasi
        '/dashboard': (context) => DashboardScreen(
            userId: ModalRoute.of(context)!.settings.arguments
            as String), // Menambahkan userId
      },
    );
  }
}
