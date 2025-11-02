import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final _db = FirebaseDatabase.instance.ref();

  //  Ghi dữ liệu (Create/Update)
  Future<void> writeData(String path, Map<String, dynamic> data) async {
    await _db.child(path).set(data);
  }

  //  Đọc dữ liệu 1 lần (One-time read)
  Future<DataSnapshot> readData(String path) async {
    return await _db.child(path).get();
  }

  //  Theo dõi thay đổi real-time
  Stream<DatabaseEvent> streamData(String path) {
    return _db.child(path).onValue;
  }

  //  Xóa dữ liệu
  Future<void> deleteData(String path) async {
    await _db.child(path).remove();
  }
}
