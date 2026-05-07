import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/product.dart';
import '../models/order.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final DatabaseService _db = DatabaseService();
  List<CartItemModel> _cartItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) {
      setState(() {
        _cartItems = [];
        _isLoading = false;
      });
      return;
    }

    var cart = await _db.getCart(userId);
    setState(() {
      if (cart != null && cart['items'] != null) {
        _cartItems = (cart['items'] as List)
            .map((item) => CartItemModel.fromMap(item as Map<String, dynamic>))
            .toList();
      } else {
        _cartItems = [];
      }
      _isLoading = false;
    });
  }

  Future<void> _updateQuantity(int index, int newQuantity) async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    if (newQuantity <= 0) {
      await _db.removeFromCart(userId, _cartItems[index].productId);
      setState(() {
        _cartItems.removeAt(index);
      });
    } else {
      await _db.updateCartItemQuantity(
        userId,
        _cartItems[index].productId,
        newQuantity,
      );
      setState(() {
        _cartItems[index].quantity = newQuantity;
      });
    }
  }

  Future<void> _checkout() async {
    if (_cartItems.isEmpty) return;

    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    String userName = FirebaseAuth.instance.currentUser?.displayName ?? '';

    var userData = await _db.getUserData(userId);
    String orderId = DateTime.now().millisecondsSinceEpoch.toString();

    OrderModel order = OrderModel(
      id: orderId,
      userId: userId,
      userName: userData?['name'] ?? userName,
      userPhone: userData?['phone'] ?? '',
      userAddress: userData?['address'] ?? '',
      items: _cartItems,
      totalPrice: _getTotalPrice(),
      status: 'pending',
      createdAt: DateTime.now(),
    );

    await _db.createOrder(order);
    await _db.clearCart(userId);

    setState(() {
      _cartItems = [];
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تأكيد الطلب بنجاح!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  double _getTotalPrice() {
    return _cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سلة المشتريات'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('السلة فارغة'),
          ],
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                CartItemModel item = _cartItems[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.shopping_bag,
                            color: Colors.blue.shade300,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.price.toStringAsFixed(2)} ر.س',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove,
                                  size: 20),
                              onPressed: () => _updateQuantity(
                                  index, item.quantity - 1),
                            ),
                            Text(
                              item.quantity.toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 20),
                              onPressed: () => _updateQuantity(
                                  index, item.quantity + 1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'الإجمالي:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_getTotalPrice().toStringAsFixed(2)} ر.س',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _checkout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'تأكيد الطلب',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}