import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tow_way_shop/customer/product_card.dart';
import 'package:tow_way_shop/customer/profile_page.dart';
import '../auth/auth_service.dart';
import '../services/database_service.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../services/share_app_service.dart';
import 'cart_page.dart';

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
  Map<String, dynamic>? _userData;
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
    _loadUserData();
  }
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  //  التحقق من تسجيل الدخول
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
  //  تحميل بيانات المستخدم
  Future<void> _loadUserData() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isNotEmpty) {
      var data = await _db.getUserData(userId);
      setState(() {
        _userData = data;
      });
    }
  }
  //  إعادة تحميل البيانات
  Future<void> _refreshProducts() async {
    setState(() => _isRefreshing = true);
    await _loadUserData();
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }
  // إضافة إلى السلة مع معالجة الأخطاء
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
            content: Text(' تم إضافة ${product.name} إلى السلة'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' حدث خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  //  تسجيل الخروج
  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) =>  AuthScreen()),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('تسجيل خروج'),
          ),
        ],
      ),
    );
  }
  //  عرض خطأ الصلاحيات بشكل جميل
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
  //  بناء القائمة الجانبية (Drawer)
  Widget _buildDrawer() {
    User? user = FirebaseAuth.instance.currentUser;
    String displayName = _userData?['name'] ?? user?.displayName ?? user?.email?.split('@')[0] ?? 'زائر';
    String userEmail = user?.email ?? 'لا يوجد بريد';
    String userPhone = _userData?['phone'] ?? 'غير مضاف';
    String userAddress = _userData?['address'] ?? 'غير مضاف';

    return Drawer(
      child: Container(
        color: Colors.white60,
        child: Column(
          children: [
            //  Header - صورة وبيانات المستخدم
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.white60, Colors.white60],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // صورة المستخدم
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.black12,
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.black12,
                      child: user?.photoURL != null
                          ? ClipOval(
                        child: Image.network(
                          user!.photoURL!,
                          width: 84,
                          height: 84,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.blue,
                          ),
                        ),
                      )
                          : Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  _buildInfoRow(Icons.phone, 'الجوال', userPhone),
                  const Divider(color: Colors.black, height: 12),
                  _buildInfoRow(Icons.location_on, 'العنوان', userAddress),
                ],
              ),
            ),

            const Divider(color: Colors.black, height: 0),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // المنتجات (الصفحة الحالية)
                  ListTile(
                    leading: const Icon(Icons.store, color: Colors.black),
                    title: const Text('المنتجات', style: TextStyle(color: Colors.black)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black),
                    selected: true,
                    selectedTileColor: Colors.black.withOpacity(0.1),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.shopping_cart, color: Colors.black),
                    title: const Text('سلة المشتريات', style: TextStyle(color: Colors.black)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
                    },
                  ),

                  // الملف الشخصي
                  ListTile(
                    leading: const Icon(Icons.person, color: Colors.black),
                    title: const Text('الملف الشخصي', style: TextStyle(color: Colors.black)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      ).then((_) => _loadUserData()); // تحديث البيانات عند العودة
                    },
                  ),

                  const Divider(color: Colors.black, height: 20),

                  // مشاركة التطبيق
                  ListTile(
                    leading: const Icon(Icons.share, color: Colors.black),
                    title: const Text('مشاركة التطبيق', style: TextStyle(color: Colors.black)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) =>  AboutDialog()),
                      ).then((_) => _loadUserData());
                      ShareAppService.shareAppLink(context);
                    },
                  ),

                  // معلومات التطبيق
                  ListTile(
                    leading: const Icon(Icons.info, color: Colors.black),
                    title: const Text('معلومات عن التطبيق', style: TextStyle(color: Colors.black)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black),
                    onTap: () {
                      Navigator.pop(context);
                      _showAboutDialog();
                    },
                  ),

                  const Divider(color: Colors.black, height: 20),

                  // تسجيل خروج
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('تسجيل خروج', style: TextStyle(color: Colors.red)),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.redAccent),
                    onTap: () {
                      Navigator.pop(context);
                      _logout();
                    },
                  ),
                ],
              ),
            ),

            //  نسخة التطبيق
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'الإصدار 2.1.0',
                style: TextStyle(color: Colors.black, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //  صف معلومات المستخدم
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white70),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  //  نافذة معلومات التطبيق
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('عن Xinancial'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_bag, size: 60, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Xinancial',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'تطبيق تسوق سهل وسريع',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _buildAboutRow('الإصدار', '1.0.0'),
            _buildAboutRow('المطور', 'Xinancial '),
            _buildAboutRow('البريد', 'support@towway.com'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المنتجات'),
        backgroundColor: Colors.white60,
        foregroundColor: Colors.black,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          //  زر السلة مع عداد
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
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
      drawer: _buildDrawer(), //  إضافة القائمة الجانبية
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: RefreshIndicator(
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

              // فلاتر التصنيفات
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
                            ? const Icon(Icons.check, size: 16, color: Colors.purple)
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
                    products = products.where((product) {
                      bool matchSearch = _searchQuery.isEmpty ||
                          product.name.toLowerCase().contains(_searchQuery);
                      bool matchCategory = _selectedCategory == 'الكل' ||
                          product.category == _selectedCategory;
                      return matchSearch && matchCategory;
                    }).toList();
                    if (products.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('لا توجد منتجات'),
                          ],
                        ),
                      );
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
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
      ),
    );
  }
}