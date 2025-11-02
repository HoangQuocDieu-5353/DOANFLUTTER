import 'package:firebase_database/firebase_database.dart';
import 'package:cuahanghoa_flutter/models/banner_model.dart';

class BannerService {
  final _db = FirebaseDatabase.instance.ref('banners');

  ///  Stream realtime danh sách banner
  Stream<List<BannerModel>> streamBanners() {
    return _db.onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) return [];
      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
      return data.entries.map((e) {
        final map = Map<String, dynamic>.from(e.value);
        return BannerModel.fromMap(map, e.key);
      }).toList();
    });
  }

  ///  Thêm banner mới (đã có link & imageUrl từ Cloudinary)
  Future<void> addBanner(BannerModel banner) async {
    await _db.child(banner.id).set(banner.toMap());
  }

  ///  Xóa banner
  Future<void> deleteBanner(String id) async {
    await _db.child(id).remove();
  }

  ///  Ẩn/Hiện banner
  Future<void> toggleBannerStatus(String id, bool newStatus) async {
    await _db.child(id).update({'isActive': newStatus});
  }
}
