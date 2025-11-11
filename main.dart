import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
  options: FirebaseOptions(
    apiKey: "AIzaSyCf_6kubnwtiIlBL2Zuxysdj2i_v-SrA_M",
    authDomain: "foodshop-9dcfc.firebaseapp.com",
    projectId: "foodshop-9dcfc",
    storageBucket: "foodshop-9dcfc.firebasestorage.app",
    messagingSenderId: "25142275189",
    appId: "1:25142275189:web:e1dd5b844244b072c9dc3c",
    measurementId: "G-TNV37ZDWDT",
  ),
  );
  // 1. TẠO MỘT BIẾN LOKAL CHO INSTANCE FIRESTORE TRƯỚC
  FirebaseFirestore firestoreInstance = FirebaseFirestore.instance;
  
  // 2. CẤU HÌNH CÀI ĐẶT TRÊN INSTANCE NÀY
  firestoreInstance.settings = const Settings(
    persistenceEnabled: true, 
    // Tùy chọn: Đặt kích thước cache không giới hạn (hoặc một giá trị cụ thể)
    // Mặc định là 40MB
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // hoặc giá trị tùy chỉnh
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
    const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodShop',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.userChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasData) return HomeScreen();
          return LoginScreen();
        },
      ),
    );
  }
}
