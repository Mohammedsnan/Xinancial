import 'package:flutter/material.dart';

class CartItemModel {
  String productId;
  String name;
  double price;
  int quantity;
  String? imageUrl;

  CartItemModel({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
      imageUrl: map['imageUrl'],
    );
  }

  double get totalPrice => price * quantity;
}

class OrderModel {
  String id;
  String userId;
  String userName;
  String userPhone;
  String userAddress;
  List<CartItemModel> items;
  double totalPrice;
  String status;
  DateTime createdAt;
  DateTime? updatedAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.userAddress,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory OrderModel.fromFirestore(Map<String, dynamic> data, String id) {
    List<CartItemModel> items = [];
    if (data['items'] != null) {
      items = (data['items'] as List)
          .map((item) => CartItemModel.fromMap(item as Map<String, dynamic>))
          .toList();
    }

    return OrderModel(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhone: data['userPhone'] ?? '',
      userAddress: data['userAddress'] ?? '',
      items: items,
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as dynamic)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'userAddress': userAddress,
      'items': items.map((e) => e.toMap()).toList(),
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  String getStatusText() {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'accepted':
        return 'تم القبول';
      case 'rejected':
        return 'مرفوض';
      case 'delivered':
        return 'تم التوصيل';
      default:
        return status;
    }
  }

  Color getStatusColor() {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'delivered':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}