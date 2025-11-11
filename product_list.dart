import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  String searchKeyword = "";
  String? selectedCategory = 'Tất cả';
  String sortField = 'createdAt';
  bool sortDesc = true;

  // 💡 BIẾN MỚI CHO PHÂN TRANG
  int _currentPage = 1;
  final int _pageSize = 5; // Kích thước trang cố định cho báo cáo

  final List<String> categories = ['Tất cả', 'Điện thoại', 'Laptop', 'Phụ kiện'];

  final FirestoreService _service = FirestoreService();

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    super.dispose();
  }

  // 💡 WIDGET CHỌN TRANG 1, 2, 3...
  Widget _buildPageSelector({required int totalPages}) {
    // Không hiển thị nếu chỉ có 1 trang hoặc ít hơn
    if (totalPages <= 1) return const SizedBox.shrink();

    // Đảm bảo trang hiện tại không vượt quá tổng số trang (xử lý khi bộ lọc thay đổi)
    if (_currentPage > totalPages) {
      _currentPage = totalPages;
      // Dùng Future.microtask để setState không bị gọi trong khi build
      Future.microtask(() => setState(() {}));
    }

    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalPages, (index) {
                final pageNumber = index + 1;
                final isSelected = pageNumber == _currentPage;

                return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton(
                        onPressed: isSelected ? null : () {
                            setState(() {
                                _currentPage = pageNumber; // Thay đổi trang hiện tại
                            });
                            // StreamBuilder sẽ tự động chạy lại và áp dụng phân trang mới
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected ? Colors.blue : Colors.grey,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                        ),
                        child: Text(
                            '$pageNumber',
                            style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                        ),
                    ),
                );
            }),
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double? minPriceForService = _minPriceController.text.trim().isEmpty
        ? null
        : double.tryParse(_minPriceController.text.trim());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Danh sách sản phẩm"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ==== Bộ lọc ====
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    // Dropdown danh mục
                    DropdownButton<String>(
                      value: selectedCategory ?? 'Tất cả',
                      items: categories
                          .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value;
                          _currentPage = 1; // Reset về trang 1 khi lọc thay đổi
                        });
                      },
                    ),
                    const SizedBox(width: 8),

                    // Ô tìm kiếm
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: "Tên sản phẩm",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchKeyword = value.trim();
                            _currentPage = 1; // Reset về trang 1 khi lọc thay đổi
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),

                const SizedBox(height: 8),

                // Sắp xếp
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Sắp xếp theo: "),
                    DropdownButton<String>(
                      value: sortField,
                      items: const [
                        DropdownMenuItem(
                            value: 'createdAt', child: Text("Ngày tạo")),
                        DropdownMenuItem(value: 'price', child: Text("Giá")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          sortField = value!;
                          _currentPage = 1; // Reset về trang 1 khi sắp xếp thay đổi
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(
                          sortDesc ? Icons.arrow_downward : Icons.arrow_upward),
                      onPressed: () {
                        setState(() {
                          sortDesc = !sortDesc;
                          _currentPage = 1; // Reset về trang 1
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // ---
          
          // ==== Danh sách sản phẩm (StreamBuilder) ====
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _service.getProducts(
                category: selectedCategory,
                minPrice: minPriceForService,
                orderByField: sortField,
                descending: sortDesc,
                maxLimit: 100,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Không có sản phẩm nào."));
                }

                // 1. Áp dụng lọc Tên (Client-side Filtering)
                var allProducts = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final matchesSearch = searchKeyword.isEmpty ||
                      name.contains(searchKeyword.toLowerCase());
                  return matchesSearch;
                }).toList();

                if (allProducts.isEmpty) {
                  return const Center(child: Text("Không có sản phẩm nào phù hợp với bộ lọc."));
                }
                
                // 2. TÍNH TOÁN PHÂN TRANG CLIENT-SIDE
                final totalCount = allProducts.length;
                final totalPages = (totalCount / _pageSize).ceil();
                final offset = (_currentPage - 1) * _pageSize;
                // 3. LẤY DANH SÁCH SẢN PHẨM TRANG HIỆN TẠI (Skip and Take)
                final displayedProducts = allProducts
                    .skip(offset)
                    .take(_pageSize)
                    .toList();

                return Column(
                  children: [
                    // Hiển thị bộ chọn trang
                    _buildPageSelector(totalPages: totalPages), 
                    
                    // Danh sách sản phẩm
                    Expanded(
                      child: ListView.builder(
                        itemCount: displayedProducts.length,
                        itemBuilder: (context, index) {
                          final data = displayedProducts[index].data() as Map<String, dynamic>;
                          return Card(
                            child: ListTile(
                              title: Text(data['name'] ?? 'Không tên'),
                              subtitle: Text(
                                  "Giá: ${data['price']} đ - Loại: ${data['category'] ?? 'Chưa rõ'}"),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}