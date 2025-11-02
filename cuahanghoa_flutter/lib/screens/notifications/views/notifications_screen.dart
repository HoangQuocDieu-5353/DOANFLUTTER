
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cuahanghoa_flutter/route/route_constants.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final user = FirebaseAuth.instance.currentUser;
  late DatabaseReference _notificationsRef;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _notificationsRef = FirebaseDatabase.instance.ref('notifications/${user!.uid}');
    }
  }

  Future<void> _ensureLoggedIn() async {
    if (user == null && mounted) {
      // Nếu chưa đăng nhập thì chuyển về login
      Navigator.pushNamedAndRemoveUntil(context, logInScreenRoute, (r) => false);
    }
  }

  Future<void> _markAsRead(String key) async {
    if (user == null) return;
    await _notificationsRef.child(key).update({'isRead': true});
  }

  Future<void> _markAllRead(Map<dynamic, dynamic>? all) async {
    if (user == null || all == null) return;
    final updates = <String, Object?>{};
    all.forEach((k, v) {
      updates['$k/isRead'] = true;
    });
    await _notificationsRef.update(updates);
  }

  @override
  Widget build(BuildContext context) {
    // kiểm tra đăng nhập ngay khi build
    if (user == null) {
      // Delay 0 để chạy sau frame hiện tại
      Future.microtask(() => _ensureLoggedIn());
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Thông báo', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            tooltip: 'Đánh dấu tất cả đã đọc',
            icon: const Icon(Icons.mark_email_read_outlined),
            onPressed: () async {
              final snap = await _notificationsRef.get();
              if (snap.exists) {
                await _markAllRead(snap.value as Map<dynamic, dynamic>?);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã đánh dấu tất cả đã đọc')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _notificationsRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('Bạn chưa có thông báo nào'));
          }

          final raw = snapshot.data!.snapshot.value;
          if (raw == null) return const Center(child: Text('Bạn chưa có thông báo nào'));

          final map = Map<String, dynamic>.from(raw as Map);
          // Chuyển sang danh sách có key
          final items = map.entries.map((e) {
            final v = Map<String, dynamic>.from(e.value as Map);
            return {
              'key': e.key,
              'title': v['title'] ?? '',
              'body': v['body'] ?? '',
              'type': v['type'] ?? '',
              'isRead': v['isRead'] ?? false,
              'createdAt': v['createdAt'] ?? '',
            };
          }).toList();

          // sort theo thời gian (mới nhất lên trên) nếu có createdAt iso
          items.sort((a, b) {
            try {
              final da = a['createdAt'] != null && a['createdAt'] != '' ? DateTime.parse(a['createdAt']) : DateTime.fromMillisecondsSinceEpoch(0);
              final db = b['createdAt'] != null && b['createdAt'] != '' ? DateTime.parse(b['createdAt']) : DateTime.fromMillisecondsSinceEpoch(0);
              return db.compareTo(da);
            } catch (_) {
              return 0;
            }
          });

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final item = items[index];
              final isRead = item['isRead'] == true;
              final createdAtStr = item['createdAt'] ?? '';
              String timeText = '';
              try {
                if (createdAtStr != '') {
                  final dt = DateTime.parse(createdAtStr);
                  timeText = DateFormat('dd/MM/yyyy HH:mm').format(dt);
                }
              } catch (_) {}
              return ListTile(
                tileColor: isRead ? Colors.white : Colors.blue.withOpacity(0.03),
                title: Text(item['title'] ?? '', style: TextStyle(fontWeight: isRead ? FontWeight.w500 : FontWeight.w700)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Text(item['body'] ?? ''),
                    if (timeText.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(timeText, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ],
                ),
                trailing: isRead ? null : const Icon(Icons.circle, size: 10, color: Colors.blueAccent),
                onTap: () async {
                  // khi nhấn: mark read + show chi tiết nhỏ
                  await _markAsRead(item['key'] as String);
                  showModalBottomSheet(
                    context: context,
                    builder: (ctx) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['title'] ?? '', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(item['body'] ?? ''),
                          const SizedBox(height: 12),
                          Text(timeText, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
                          )
                        ],
                      ),
                    )
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
