import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tow_way_shop/customer/product_card.dart';
import '../auth/auth_service.dart';
import '../services/database_service.dart';
import '../models/product.dart';
import '../models/order.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'الكل';
  String _searchQuery = '';
  bool _isRefreshing = false;

  final List<String> _categories = [
    'الكل',
    'جوالات',
    'أجهزة لوحية',
    'لابتوبات',
    'اكسسوارات',
    'إلكترونيات',
  ];

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ✅ التحقق من تسجيل الدخول
  void _checkAuth() {
    if (FirebaseAuth.instance.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) =>  AuthScreen()),
        );
      });
    }
  }

  // ✅ إعادة تحميل البيانات
  Future<void> _refreshProducts() async {
    setState(() => _isRefreshing = true);
    // انتظر ثانية لتحديث البيانات
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  // ✅ إضافة إلى السلة مع معالجة الأخطاء
  Future<void> _addToCart(Product product) async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (userId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء تسجيل الدخول أولاً'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) =>  AuthScreen()),
        );
      }
      return;
    }

    if (product.quantity <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} غير متوفر حالياً'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    CartItemModel item = CartItemModel(
      productId: product.id,
      name: product.name,
      price: product.price,
      quantity: 1,
      imageUrl: product.imageUrl,
    );

    try {
      await _db.addToCart(userId, item);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم إضافة ${product.name} إلى السلة'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ حدث خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ عرض خطأ الصلاحيات بشكل جميل
  Widget _buildPermissionDenied() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 80, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'لا توجد صلاحية لعرض المنتجات',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            'تأكد من اتصالك بالإنترنت أو تواصل مع الدعم',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _refreshProducts();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) =>  AuthScreen()),
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text('تسجيل الدخول بحساب آخر'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المنتجات'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // ✅ زر السلة مع عداد
          StreamBuilder<Map<String, dynamic>?>(
            stream: _db.getCartStream(FirebaseAuth.instance.currentUser?.uid ?? ''),
            builder: (context, snapshot) {
              int cartCount = 0;
              if (snapshot.hasData && snapshot.data != null) {
                var items = snapshot.data!['items'] as List? ?? [];
                cartCount = items.length;
              }
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      // انتقل إلى صفحة السلة
                      Navigator.pushNamed(context, '/cart');
                    },
                  ),
                  if (cartCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        child: Column(
          children: [
            // شريط البحث
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'بحث عن منتج...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.toLowerCase());
                  },
                ),
              ),
            ),

            // فلاتر التصنيفات - قابلة للتمرير الأفقية
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() => _selectedCategory = category);
                      },
                      backgroundColor: Colors.grey.shade100,
                      selectedColor: Colors.blue.shade100,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      avatar: isSelected
                          ? const Icon(Icons.check, size: 16, color: Colors.blue)
                          : null,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // قائمة المنتجات
            Expanded(
              child: _isRefreshing
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<List<Product>>(
                stream: _db.getProducts(),
                builder: (context, snapshot) {
                  // ✅ معالجة خطأ الصلاحيات
                  if (snapshot.hasError) {
                    String errorMsg = snapshot.error.toString();
                    if (errorMsg.contains('permission-denied')) {
                      return _buildPermissionDenied();
                    }
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
                          const SizedBox(height: 16),
                          Text('خطأ: ${snapshot.error}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _refreshProducts,
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting && !_isRefreshing) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('جاري تحميل المنتجات...'),
                        ],
                      ),
                    );
                  }

                  var products = snapshot.data ?? [];

                  // التصفية حسب البحث والتصنيف
                  products = products.where((product) {
                    bool matchSearch = _searchQuery.isEmpty ||
                        product.name.toLowerCase().contains(_searchQuery);
                    bool matchCategory = _selectedCategory == 'الكل' ||
                        product.category == _selectedCategory;
                    return matchSearch && matchCategory;
                  }).toList();

                  if (products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty || _selectedCategory != 'الكل'
                                ? 'لا توجد منتجات مطابقة للبحث'
                                : 'لا توجد منتجات',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          if (_searchQuery.isNotEmpty || _selectedCategory != 'الكل')
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _selectedCategory = 'الكل';
                                  _searchController.clear();
                                });
                              },
                              child: const Text('مسح الفلتر'),
                            ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return ProductCard(
                        product: products[index],
                        onAddToCart: () => _addToCart(products[index]),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}