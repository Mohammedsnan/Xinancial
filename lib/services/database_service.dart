import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart';
import '../models/product.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== المنتجات ====================
  Stream<List<Product>> getProducts() {
    return _firestore
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      ))
          .toList();
    });
  }
  // للحصول على Stream للسلة (لعداد الأيقونة)
  Stream<Map<String, dynamic>?> getCartStream(String userId) {
    if (userId.isEmpty) return Stream.value(null);
    return _firestore.collection('carts').doc(userId).snapshots().map((doc) {
      return doc.exists ? doc.data() : null;
    });
  }
  Future<Product?> getProductById(String productId) async {
    var doc = await _firestore.collection('products').doc(productId).get();
    if (doc.exists) {
      return Product.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }
    return null;
  }
  // ==================== السلة ====================
  Future<Map<String, dynamic>?> getCart(String userId) async {
    var doc = await _firestore.collection('carts').doc(userId).get();
    return doc.exists ? doc.data() : null;
  }
  Future<void> saveCart(String userId, Map<String, dynamic> cartData) async {
    await _firestore.collection('carts').doc(userId).set(cartData);
  }
  Future<void> addToCart(String userId, CartItemModel item) async {
    var cart = await getCart(userId);
    List<dynamic> items = cart?['items'] ?? [];

    int index = items.indexWhere((i) => i['productId'] == item.productId);
    if (index != -1) {
      items[index]['quantity'] += item.quantity;
    } else {
      items.add(item.toMap());
    }

    await saveCart(userId, {'items': items});
  }

  Future<void> removeFromCart(String userId, String productId) async {
    var cart = await getCart(userId);
    if (cart != null && cart['items'] != null) {
      List<dynamic> items = cart['items'];
      items.removeWhere((item) => item['productId'] == productId);
      await saveCart(userId, {'items': items});
    }
  }

  Future<void> updateCartItemQuantity(
      String userId,
      String productId,
      int quantity,
      ) async {
    var cart = await getCart(userId);
    if (cart != null && cart['items'] != null) {
      List<dynamic> items = cart['items'];
      int index = items.indexWhere((item) => item['productId'] == productId);
      if (index != -1) {
        if (quantity <= 0) {
          items.removeAt(index);
        } else {
          items[index]['quantity'] = quantity;
        }
        await saveCart(userId, {'items': items});
      }
    }
  }

  Future<void> clearCart(String userId) async {
    await _firestore.collection('carts').doc(userId).delete();
  }

  // ==================== الطلبات ====================
  Future<void> createOrder(OrderModel order) async {
    await _firestore.collection('orders').doc(order.id).set(order.toMap());

    // تحديث كمية المنتجات في المخزون
    for (var item in order.items) {
      var product = await getProductById(item.productId);
      if (product != null) {
        await _firestore.collection('products').doc(item.productId).update({
          'quantity': product.quantity - item.quantity,
        });
      }
    }
  }

  Stream<List<OrderModel>> getUserOrders(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      ))
          .toList();
    });
  }

  // ==================== بيانات المستخدم ====================
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    var doc = await _firestore.collection('users').doc(userId).get();
    return doc.exists ? doc.data() : null;
  }

  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).set(
      data,
      SetOptions(merge: true),
    );
  }
}