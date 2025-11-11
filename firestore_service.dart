import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference _products =
      FirebaseFirestore.instance.collection('products');

  // Thêm sản phẩm
  Future<void> addProduct(Map<String, dynamic> data) async {
    // Luôn thêm trường category_lower cho việc tìm kiếm case-insensitive
    data['category_lower'] = (data['category'] ?? '').toString().trim().toLowerCase();
    // Thêm Timestamp cho việc sắp xếp
    data['createdAt'] = FieldValue.serverTimestamp(); 
    await _products.add(data);
  }
  
  // Xóa sản phẩm
  Future<void> deleteProduct(String id) async {
    await _products.doc(id).delete();
  }

  // Cập nhật sản phẩm
  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await _products.doc(id).update(data);
  }

  // === Complex Query: where, orderBy, limit ===
  Stream<QuerySnapshot> getProducts({
    String? category,
    double? minPrice,
    String orderByField = 'createdAt',
    bool descending = true,
    int? maxLimit,
  }) {
    // 1. Luôn bắt đầu từ Collection Reference gốc
    Query query = _products;

    // 1a. Lọc theo Danh mục (WHERE)
    if (category != null && category.isNotEmpty && category != 'Tất cả') {
      query = query.where(
        'category_lower',
        isEqualTo: category.toLowerCase().trim(),
      );
    }

    query = query.orderBy(orderByField, descending: descending);
    
    // 4. Giới hạn (LIMIT)
    if (maxLimit != null && maxLimit > 0) {
      query = query.limit(maxLimit);
    }

    return query.snapshots();
  }
}