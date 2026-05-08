import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../models/product.dart';
import '../services/excel_service.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ExcelService _excelService = ExcelService();

  // استيراد المنتجات من Excel
  Future<void> _importFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );
      if (result != null) {
        List<Product> products = await _excelService.readProductsFromExcel(result.files.first.path!);

        for (var product in products) {
          await _firestore.collection('products').doc(product.id).set(product.toMap());
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم استيراد ${products.length} منتج بنجاح')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    }
  }
  Future<void> _deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المنتجات'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _importFromExcel,
            tooltip: 'استيراد من Excel',
          ),
        ],
      ),
      body: Column(
        children: [
          // زر إضافة منتج جديد
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => _showProductDialog(),
              icon: const Icon(Icons.add),
              label: const Text('إضافة منتج جديد'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('products').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('خطأ: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var products = snapshot.data!.docs.map((doc) =>
                    Product.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    Product product = products[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Text(product.name[0]),
                        ),
                        title: Text(product.name),
                        subtitle: Text(
                          '${product.price.toStringAsFixed(2)} RMS  | الكمية: ${product.quantity} | ${product.category}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _showProductDialog(product: product),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteProduct(product.id),
                            ),
                          ],
                        ),
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

  void _showProductDialog({Product? product}) {
    final formKey = GlobalKey<FormState>();
    TextEditingController nameController = TextEditingController(text: product?.name ?? '');
    TextEditingController priceController = TextEditingController(text: product?.price.toString() ?? '');
    TextEditingController quantityController = TextEditingController(text: product?.quantity.toString() ?? '');
    TextEditingController descriptionController = TextEditingController(text: product?.description ?? '');
    TextEditingController categoryController = TextEditingController(text: product?.category ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product == null ? 'إضافة منتج جديد' : 'تعديل المنتج'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم المنتج'),
                  validator: (v) => v?.isEmpty ?? true ? 'الحقل مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'السعر'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v?.isEmpty ?? true ? 'الحقل مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: quantityController,
                  decoration: const InputDecoration(labelText: 'الكمية'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'الوصف'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'التصنيف'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                if (product == null) {
                  // إضافة جديد
                  String newId = DateTime.now().millisecondsSinceEpoch.toString();
                  Product newProduct = Product(
                    id: newId,
                    name: nameController.text,
                    price: double.parse(priceController.text),
                    quantity: int.parse(quantityController.text),
                    description: descriptionController.text,
                    category: categoryController.text,
                    imageUrl: '',
                    createdAt: DateTime.now(),
                  );
                  await _firestore.collection('products').doc(newId).set(newProduct.toMap());
                } else {
                  await _firestore.collection('products').doc(product.id).update({
                    'name': nameController.text,
                    'price': double.parse(priceController.text),
                    'quantity': int.parse(quantityController.text),
                    'description': descriptionController.text,
                    'category': categoryController.text,
                  });
                }
                Navigator.pop(context);
              }
            },
            child: Text(product == null ? 'إضافة' : 'حفظ'),
          ),
        ],
      ),
    );
  }
}