class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final int stock;
  final String category;
  final bool isBestSeller; 
  final bool isNew;
  final bool isPopular; 
  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.stock,
    required this.category,
    this.isBestSeller = false,
    this.isNew = false,
    this.isPopular = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'stock': stock,
      'category': category,
      'isBestSeller': isBestSeller,
      'isNew': isNew,
      'isPopular': isPopular,
    };
  }

  factory ProductModel.fromMap(Map<dynamic, dynamic> map, String id) {
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return ProductModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: parsePrice(map['price']),
      imageUrl: map['imageUrl'] ?? '',
      stock: (map['stock'] ?? 0).toInt(),
      category: map['category'] ?? '',
      isBestSeller: map['isBestSeller'] ?? false,
      isNew: map['isNew'] ?? false,
      isPopular: map['isPopular'] ?? false,
    );
  }
}
