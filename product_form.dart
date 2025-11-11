import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class ProductForm extends StatefulWidget {
  final String? productId;
  final Map<String, dynamic>? initialData;

  const ProductForm({super.key, this.productId, this.initialData});

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();

  final FirestoreService _service = FirestoreService();
  String? _editingId;

  final List<String> categories = ['Điện thoại', 'Laptop', 'Phụ kiện'];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _editingId = widget.productId;
      _nameController.text = widget.initialData!['name'] ?? '';
      _priceController.text = widget.initialData!['price'].toString();
      _categoryController.text = widget.initialData!['category'] ?? '';
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final double? price = double.tryParse(_priceController.text);
      if (price == null || price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giá phải là số dương!')),
        );
        return;
      }

      final data = {
        'name': _nameController.text,
        'price': price,
        'category': _categoryController.text.trim(),
        'category_lower': _categoryController.text.toLowerCase(),
        'createdAt': _editingId == null ? Timestamp.now() : widget.initialData!['createdAt'],
        'updatedAt': Timestamp.now(),
      };

      try {
        if (_editingId == null) {
          await _service.addProduct(data);
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Đã thêm sản phẩm!')));
        } else {
          await _service.updateProduct(_editingId!, data);
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Đã cập nhật sản phẩm!')));
          _editingId = null;
        }

        _nameController.clear();
        _priceController.clear();
        _categoryController.clear();
        FocusScope.of(context).unfocus();
        setState(() {});
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  void _editProduct(String id, Map<String, dynamic> data) {
    setState(() {
      _editingId = id;
      _nameController.text = data['name'] ?? '';
      _priceController.text = data['price'].toString();
      _categoryController.text = data['category'] ?? '';
    });
  }

  void _deleteProduct(String id) async {
    try {
      await _service.deleteProduct(id);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã xóa sản phẩm!')));
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // ==== Form thêm / sửa ====
          Card(
            elevation: 4,
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      _editingId == null ? 'Tạo sản phẩm mới' : 'Sửa sản phẩm',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Tên sản phẩm'),
                      validator: (v) => v!.isEmpty ? 'Nhập tên sản phẩm' : null,
                    ),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Giá'),
                      validator: (v) => v!.isEmpty ? 'Nhập giá' : null,
                    ),
                    DropdownButtonFormField<String>(
                      value: _categoryController.text.isNotEmpty
                          ? _categoryController.text
                          : null,
                      items: categories
                          .map((cat) => DropdownMenuItem(
                              value: cat, child: Text(cat)))
                          .toList(),
                      onChanged: (value) {
                        _categoryController.text = value!;
                      },
                      decoration: const InputDecoration(labelText: 'Danh mục'),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Chọn danh mục'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _submit,
                      child: Text(_editingId == null
                          ? 'Thêm sản phẩm'
                          : 'Cập nhật sản phẩm'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ==== Danh sách sản phẩm ====
          Card(
            elevation: 4,
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Danh sách sản phẩm',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: _service.getProducts(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }

                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const Text('Chưa có sản phẩm nào.');
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>? ?? {};

                          return ListTile(
                            title: Text(data['name'] ?? 'Không tên'),
                            subtitle: Text(
                                'Giá: ${data['price']} - Danh mục: ${data['category']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blueAccent),
                                  onPressed: () => _editProduct(doc.id, data),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.redAccent),
                                  onPressed: () => _deleteProduct(doc.id),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
