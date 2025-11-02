  import 'package:firebase_database/firebase_database.dart';
  class BannerModel {
    final String id;
    final String imageUrl;
    final String? link;
    final bool isActive;
    final int? createdAt; 

    BannerModel({
      required this.id,
      required this.imageUrl,
      this.link,
      this.isActive = true,
      this.createdAt,
    });

    factory BannerModel.fromMap(Map<dynamic, dynamic> data, String id) {
      return BannerModel(
        id: id,
        imageUrl: data['imageUrl'] ?? '',
        link: data['link'],
        isActive: data['isActive'] ?? true,
        createdAt: data['createdAt'],
      );
    }

    Map<String, dynamic> toMap() {
      return {
        'imageUrl': imageUrl,
        'link': link ?? '',
        'isActive': isActive,
        'createdAt': ServerValue.timestamp,
      };
    }
  }
