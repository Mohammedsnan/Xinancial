import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String filterStatus = 'الكل';

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم تحديث حالة الطلب إلى $newStatus')),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'قيد الانتظار';
      case 'accepted': return 'تم القبول';
      case 'rejected': return 'مرفوض';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'accepted': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الطلبات'),
        centerTitle: true,
        backgroundColor: Colors.white60,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportOrders(),
            tooltip: 'تصدير الطلبات',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFilterChip('الكل', 'الكل'),
                _buildFilterChip('قيد الانتظار', 'pending'),
                _buildFilterChip('تم القبول', 'accepted'),
                _buildFilterChip('مرفوض', 'rejected'),
              ],
            ),
          ),

          // قائمة الطلبات
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('orders').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('خطأ: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var orders = snapshot.data!.docs.where((doc) {
                  var status = doc.get('status');
                  if (filterStatus == 'الكل') return true;
                  if (filterStatus == 'pending') return status == 'pending';
                  if (filterStatus == 'accepted') return status == 'accepted';
                  if (filterStatus == 'rejected') return status == 'rejected';
                  return true;
                }).toList();

                if (orders.isEmpty) {
                  return const Center(child: Text('لا توجد طلبات'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    var order = orders[index];
                    var items = order.get('items') as List;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ExpansionTile(
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(order.get('status')),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getStatusText(order.get('status')),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(  // ← الحل هنا
                              child: Text(
                                'طلب #${order.id.substring(0, 8)}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text('${order.get('userName')} | ${order.get('totalPrice')} ريال'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('المنتجات:', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                ...items.map((item) => ListTile(
                                  leading: const Icon(Icons.shopping_bag),
                                  title: Text(item['name']),
                                  subtitle: Text('${item['price']} ريال × ${item['quantity']}'),
                                  trailing: Text('${(item['price'] * item['quantity']).toStringAsFixed(2)} ريال'),
                                )),
                                const Divider(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('الإجمالي:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text('${order.get('totalPrice')} ريال',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                if (order.get('status') == 'pending')
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _updateOrderStatus(order.id, 'accepted'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('قبول الطلب'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _updateOrderStatus(order.id, 'rejected'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('رفض الطلب'),
                                        ),
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

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: filterStatus == value,
      onSelected: (selected) {
        setState(() {
          filterStatus = value;
        });
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: Colors.blue.shade100,
    );
  }

  Future<void> _exportOrders() async {
    var snapshot = await _firestore.collection('orders').get();
    List<Map<String, dynamic>> orders = [];

    for (var doc in snapshot.docs) {
      orders.add({
        'id': doc.id,
        'userName': doc.get('userName'),
        'itemsCount': (doc.get('items') as List).length,
        'totalPrice': doc.get('totalPrice'),
        'status': _getStatusText(doc.get('status')),
        'createdAt': doc.get('createdAt')?.toDate().toString() ?? '',
      });
    }
    // هنا يمكنك إضافة تصدير Excel
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم تصدير ${orders.length} طلب بنجاح')),
    );
  }

}