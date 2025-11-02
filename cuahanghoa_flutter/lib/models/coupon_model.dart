
class CouponModel {
  final String id; 
  final String description; 
  final int discountPercentage; 
  final DateTime expirationDate; 
  final bool isEnabled; 

  CouponModel({
    required this.id,
    required this.description,
    required this.discountPercentage,
    required this.expirationDate,
    required this.isEnabled,
  });

  factory CouponModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return CouponModel(
      id: id,
      description: map['description'] ?? '',
      discountPercentage: (map['discountPercentage'] as num?)?.toInt() ?? 0,
      expirationDate: DateTime.tryParse(map['expirationDate'] ?? '') ?? DateTime.now(),
      isEnabled: map['isEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'discountPercentage': discountPercentage,
      'expirationDate': expirationDate.toIso8601String(),
      'isEnabled': isEnabled,
    };

  }
}