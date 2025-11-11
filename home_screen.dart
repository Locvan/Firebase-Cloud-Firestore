import 'package:flutter/material.dart';
import '../widgets/product_form.dart';
import '../widgets/product_list.dart';
import '../auth_service.dart'; // thêm dòng này để gọi signOut()

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService(); // khởi tạo auth

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await _authService.signOut();
    // Nếu bạn đang dùng StreamBuilder trong main.dart,
    // app sẽ tự quay lại Login khi user == null.
    // Nếu không, thêm dòng này:
    // Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý sản phẩm Firestore'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: "Danh sách sản phẩm"),
            Tab(icon: Icon(Icons.add_box), text: "Thêm sản phẩm"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _logout,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ProductListPage(), // Tab 1: xem + lọc
          ProductForm(), // Tab 2: thêm sản phẩm
        ],
      ),
    );
  }
}
