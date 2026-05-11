import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'admin_products.dart';

class _AdminProductsPageState extends State<AdminProductsPage> {
  // ==================== المتغيرات ====================
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  String? _selectedImageUrl;
  bool _isUploading = false;

  // ==================== دوال رفع الصورة ====================

  Future<String?> _uploadImage(File imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = _storage.ref().child('products/$fileName.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      print('خطأ في رفع الصورة: $e');
      return null;
    }
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.image,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );

      if (result != null) {
        setState(() {
          _isUploading = true;
        });

        File imageFile = File(result.files.single.path!);
        String? imageUrl = await _uploadImage(imageFile);

        print('✅ تم رفع الصورة: $imageUrl');

        setState(() {
          _selectedImageUrl = imageUrl;
          _isUploading = false;
        });

        if (imageUrl != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ تم رفع الصورة بنجاح'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      print('❌ خطأ: $e');
      setState(() {
        _isUploading = false;
      });
    }
  }

  // ==================== دوال إدارة المنتجات ====================

  Future<void> _addProduct() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      _showError('يرجى ملء الاسم والسعر');
      return;
    }

    print('📸 رابط الصورة قبل الحفظ: $_selectedImageUrl');

    Map<String, dynamic> productData = {
      'name': _nameController.text,
      'price': double.parse(_priceController.text),
      'quantity': int.tryParse(_quantityController.text) ?? 0,
      'description': _descriptionController.text,
      'category': _categoryController.text,
      'imageUrl': _selectedImageUrl ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    };

    print('📦 بيانات المنتج: $productData');

    await _firestore.collection('products').add(productData);

    _clearForm();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إضافة المنتج بنجاح'), backgroundColor: Colors.green),
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
        const SnackBar(content: Text('تم تحديث المنتج بنجاح'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
  }

  Future<void> _importFromExcel() async {
    // ... كود استيراد Excel
  }

  void _clearForm() {
    _nameController.clear();
    _priceController.clear();
    _quantityController.clear();
    _descriptionController.clear();
    _categoryController.clear();
    _selectedImageUrl = null;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showProductDialog({String? productId, Map<String, dynamic>? productData}) {
    // ... كود عرض حوار الإضافة/التعديل
  }

  void _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('adminLoggedIn');
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  // ==================== دالة build ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... كود الواجهة
    );
  }
}