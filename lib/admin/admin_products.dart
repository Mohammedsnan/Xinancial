import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../auth/auth_service.dart';
import 'admin_orders.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // متغيرات لإضافة/تعديل منتج
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  String? _selectedImageUrl;
  bool _isUploading = true;
  bool _useImageUrl = false; // false = رفع ملف, true = رابط إنترنت

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );

      if (result != null) {
        setState(() => _isUploading = true);
        File imageFile = File(result.files.single.path!);
        String? imageUrl = await _uploadImage(imageFile);
        setState(() {
          _selectedImageUrl = imageUrl;
          _isUploading = false;
        });

        if (imageUrl != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(' تم رفع الصورة بنجاح'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(' خطأ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        print(' الملف غير موجود');
        return null;
      }
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child('products/$fileName');

      print(' جاري رفع الصورة: $fileName');

      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      if (snapshot.state == TaskState.success) {
        String downloadUrl = await snapshot.ref.getDownloadURL();
        print(' تم الرفع بنجاح: $downloadUrl');
        return downloadUrl;
      } else {
        print(' فشل الرفع: ${snapshot.state}');
        return null;
      }
    } catch (e) {
      print(' خطأ في رفع الصورة: $e');
      return null;
    }
  }

  Future<void> _importFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null) {
        var bytes = result.files.first.bytes;
        var excel = Excel.decodeBytes(bytes!);
        var sheet = excel.tables[excel.tables.keys.first];
        var products = <Map<String, dynamic>>[];

        for (var row in sheet!.rows.skip(1)) {
          if (row[0]?.value != null && row[0]?.value.toString().isNotEmpty == true) {
            products.add({
              'name': row[0]?.value.toString() ?? '',
              'price': double.tryParse(row[1]?.value.toString() ?? '0') ?? 0,
              'quantity': int.tryParse(row[2]?.value.toString() ?? '0') ?? 0,
              'description': row[3]?.value.toString() ?? '',
              'category': row[4]?.value.toString() ?? '',
              'imageUrl': row[5]?.value.toString() ?? '',
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        }

        for (var product in products) {
          await _firestore.collection('products').add(product);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(' تم استيراد ${products.length} منتج بنجاح')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(' خطأ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ==================== إدارة المنتجات ====================
  Future<void> _addProduct() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      _showError('يرجى ملء الاسم والسعر');
      return;
    }

    Map<String, dynamic> productData = {
      'name': _nameController.text,
      'price': double.parse(_priceController.text),
      'quantity': int.tryParse(_quantityController.text) ?? 0,
      'description': _descriptionController.text,
      'category': _categoryController.text,
      'imageUrl': _selectedImageUrl ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('products').add(productData);

    _clearForm();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(' تم إضافة المنتج بنجاح'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _updateProduct(String productId, Map<String, dynamic> currentData) async {
    Map<String, dynamic> updatedData = {
      'name': _nameController.text,
      'price': double.parse(_priceController.text),
      'quantity': int.tryParse(_quantityController.text) ?? 0,
      'description': _descriptionController.text,
      'category': _categoryController.text,
    };

    if (_selectedImageUrl != null && _selectedImageUrl != currentData['imageUrl']) {
      updatedData['imageUrl'] = _selectedImageUrl;
    }

    await _firestore.collection('products').doc(productId).update(updatedData);

    _clearForm();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(' تم تحديث المنتج بنجاح'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
  }

  void _clearForm() {
    _nameController.clear();
    _priceController.clear();
    _quantityController.clear();
    _descriptionController.clear();
    _categoryController.clear();
    _selectedImageUrl = null;
    _imageUrlController.clear();
    _useImageUrl = false;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  //   إضافة/تعديل المنتج
  void _showProductDialog({String? productId, Map<String, dynamic>? productData}) {
    _nameController.text = productData?['name'] ?? '';
    _priceController.text = productData?['price']?.toString() ?? '';
    _quantityController.text = productData?['quantity']?.toString() ?? '';
    _descriptionController.text = productData?['description'] ?? '';
    _categoryController.text = productData?['category'] ?? '';
    _selectedImageUrl = productData?['imageUrl'];
    _useImageUrl = _selectedImageUrl != null && _selectedImageUrl!.startsWith('http');
    if (_useImageUrl) {
      _imageUrlController.text = _selectedImageUrl ?? '';
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(productId == null ? ' إضافة منتج جديد' : ' تعديل المنتج'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // اختيار طريقة إضافة الصورة
                    Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment<bool>(
                                value: false,
                                label: Text(' رفع ملف'),
                                icon: Icon(Icons.upload_file),
                              ),
                              ButtonSegment<bool>(
                                value: true,
                                label: Text(' رابط إنترنت'),
                                icon: Icon(Icons.link),
                              ),
                            ],
                            selected: {_useImageUrl},
                            onSelectionChanged: (Set<bool> newSelection) {
                              setDialogState(() {
                                _useImageUrl = newSelection.first;
                                if (!_useImageUrl) {
                                  _imageUrlController.clear();
                                } else {
                                  _selectedImageUrl = null;
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // عرض حسب الطريقة المختارة
                    if (!_useImageUrl) ...[
                      // رفع ملف
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: _isUploading
                            ? const Center(child: CircularProgressIndicator())
                            : (_selectedImageUrl != null && _selectedImageUrl!.isNotEmpty)
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _selectedImageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        )
                            : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image, size: 50, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('لا توجد صورة'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isUploading ? null : () async {
                            await _pickImage();
                            setDialogState(() {});
                          },
                          icon: _isUploading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(Icons.upload_file),
                          label: Text(_isUploading ? 'جاري الرفع...' : ' رفع صورة من الجهاز'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // رابط إنترنت
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: (_selectedImageUrl != null && _selectedImageUrl!.isNotEmpty)
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _selectedImageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(child: CircularProgressIndicator());
                            },
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        )
                            : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.link, size: 50, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('أدخل رابط الصورة أدناه'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _imageUrlController,
                        decoration: InputDecoration(
                          hintText: 'https://example.com/image.jpg',
                          labelText: ' رابط الصورة',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.link),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.preview, color: Colors.black),
                            onPressed: () {
                              String url = _imageUrlController.text.trim();
                              if (url.isNotEmpty) {
                                setDialogState(() {
                                  _selectedImageUrl = url;
                                });
                              }
                            },
                            tooltip: 'معاينة الصورة',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            String url = _imageUrlController.text.trim();
                            if (url.isNotEmpty) {
                              setDialogState(() {
                                _selectedImageUrl = url;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text(' تم تعيين رابط الصورة'), backgroundColor: Colors.green),
                              );
                            }
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('تأكيد رابط الصورة'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],

                    // زر إزالة الصورة
                    if (_selectedImageUrl != null && _selectedImageUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                _selectedImageUrl = null;
                                _imageUrlController.clear();
                              });
                            },
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            label: const Text('🗑 إزالة الصورة', style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // اسم المنتج
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: ' اسم المنتج',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.production_quantity_limits),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // السعر والكمية
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(
                              labelText: ' السعر (ر.س)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            decoration: const InputDecoration(
                              labelText: ' الكمية',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.inventory),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // التصنيف
                    TextField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: ' التصنيف',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // الوصف
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: ' الوصف',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _clearForm();
                  Navigator.pop(context);
                },
                child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (productId == null) {
                    await _addProduct();
                  } else {
                    await _updateProduct(productId, productData!);
                  }
                  _clearForm();
                  if (mounted) {
                    if(Navigator.canPop(context)){
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) =>  AdminProductsPage()));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: Text(
                  productId == null ? 'إضافة' : 'حفظ',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('adminLoggedIn');
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) =>  AuthScreen()));
    }
  }

  // ==================== واجهة المستخدم الرئيسية ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المنتجات'),
        centerTitle: true,
        backgroundColor: Colors.white60,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _importFromExcel,
            tooltip: 'استيراد من Excel',
          ),
          IconButton(
            icon: const Icon(Icons.shopping_bag),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminOrdersPage()));
            },
            tooltip: 'الطلبات',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'تسجيل خروج',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showProductDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة منتج جديد', style: TextStyle(color: Colors.black)),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // شريط البحث
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: ' بحث عن منتج...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('products').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('خطأ: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                var products = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return _searchQuery.isEmpty ||
                      (data['name'] ?? '').toString().toLowerCase().contains(_searchQuery);
                }).toList();

                if (products.isEmpty) {
                  return const Center(child: Text('لا توجد منتجات'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(15),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    var doc = products[index];
                    var data = doc.data() as Map<String, dynamic>;
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // صورة المنتج
                          Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(15),
                                topRight: Radius.circular(15),
                              ),
                            ),
                            child: (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty)
                                ? CachedNetworkImage(
                              imageUrl: data['imageUrl'],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.image_not_supported,
                                size: 40,
                                color: Colors.grey.shade400,
                              ),
                            )
                                : Center(
                              child: Icon(
                                Icons.shopping_bag,
                                size: 50,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['name'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${data['price'] ?? 0} ر.س',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'الكمية: ${data['quantity'] ?? 0}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20, color: Colors.orange),
                                      onPressed: () => _showProductDialog(
                                        productId: doc.id,
                                        productData: data,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                      onPressed: () => _deleteProduct(doc.id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}