import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Koneksi ke MongoDB saat aplikasi pertama dibuka
  await DatabaseService.connect();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pencatatan Keuangan Kelompok 2',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: LoginPage(),
    );
  }
}