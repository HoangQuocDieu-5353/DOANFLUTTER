import 'package:cuahanghoa_flutter/models/cart_item.dart';

class OrderModel {
  final String id;
  final String userId;
  final List<CartItem> items;
  final int totalPrice;
  final String status;
  final DateTime createdAt;
  final String paymentMethod;
  final String address;
  final String? couponCode;
  final int discountAmount;
  final String? returnReason;     
  final List<String>? returnImages; 

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.paymentMethod,
    required this.address,
    this.couponCode,
    this.discountAmount = 0,
    this.returnReason,
    this.returnImages,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((e) => e.toJson()).toList(),
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'paymentMethod': paymentMethod,
      'address': address,
      'couponCode': couponCode,
      'discountAmount': discountAmount,

      'returnReason': returnReason,
      'returnImages': returnImages,
    };
  }

  factory OrderModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return OrderModel(
      id: id,
      userId: map['userId'] ?? '',
      items: (map['items'] as List? ?? [])
          .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      totalPrice: map['totalPrice'] ?? 0,
      status: map['status'] ?? 'pending',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      paymentMethod: map['paymentMethod'] ?? 'unknown',
      address: map['address'] ?? '',
      couponCode: map['couponCode'],
      discountAmount: (map['discountAmount'] as num?)?.toInt() ?? 0,

      returnReason: map['returnReason'],
      returnImages: (map['returnImages'] as List?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    List<CartItem>? items,
    int? totalPrice,
    String? status,
    DateTime? createdAt,
    String? paymentMethod,
    String? address,
    String? couponCode,
    int? discountAmount,

    String? returnReason,
    List<String>? returnImages,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      address: address ?? this.address,
      couponCode: couponCode ?? this.couponCode,
      discountAmount: discountAmount ?? this.discountAmount,
      returnReason: returnReason ?? this.returnReason,
      returnImages: returnImages ?? this.returnImages,
    );
  }
}
