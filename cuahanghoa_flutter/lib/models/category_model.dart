class CategoryModel {
  final String id;
  final String name;
  final String imageUrl;
  final String description;

  CategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
    };
  }

  factory CategoryModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return CategoryModel(
      id: id,
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      description: map['description'] ?? '',
    );
  }
}
