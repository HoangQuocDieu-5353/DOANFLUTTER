import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cuahanghoa_flutter/models/user_model.dart';
import 'package:cuahanghoa_flutter/services/user_service.dart';
import 'user_detail_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final UserService _userService = UserService();
  final DatabaseReference _userRef = FirebaseDatabase.instance.ref('users');

  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _listenToUsers();
  }

  ///  Lắng nghe realtime danh sách user
  void _listenToUsers() {
    _userRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final users = <UserModel>[];
        data.forEach((key, value) {
          if (value is Map) {
            users.add(UserModel.fromMap(value, key));
          }
        });
        setState(() {
          _users = users;
          _isLoading = false;
        });
      } else {
        setState(() {
          _users = [];
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quản lý người dùng")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text("Không có người dùng nào"))
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final bool isLocked = (user.role == 'locked');

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                              ? NetworkImage(user.avatarUrl!)
                              : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                        ),
                        title: Text(user.name),
                        subtitle: Text("${user.email}\nRole: ${user.role}"),
                        isThreeLine: true,
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserDetailScreen(user: user),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
