class Product {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String description;
  final String category;
  final String imageUrl;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.createdAt,
  });

  factory Product.fromFirestore(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      quantity: data['quantity'] ?? 0,
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
    };
  }

  bool get isAvailable => quantity > 0;
}