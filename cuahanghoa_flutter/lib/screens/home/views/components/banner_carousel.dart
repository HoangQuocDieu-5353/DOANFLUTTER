import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_database/firebase_database.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final CarouselSliderController _controller = CarouselSliderController();
  final DatabaseReference _db = FirebaseDatabase.instance.ref('banners');
  int _current = 0;

  /// Stream lấy banner đang active
  Stream<List<Map<String, dynamic>>> _getActiveBanners() {
    return _db.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return <Map<String, dynamic>>[];
      final banners = Map<String, dynamic>.from(data as Map);
      return banners.entries.map((e) {
        final map = Map<String, dynamic>.from(e.value);
        return {
          "id": e.key,
          "imageUrl": map["imageUrl"] ?? "",
          "link": map["link"],
          "isActive": map["isActive"] ?? true,
        };
      }).where((b) => b["isActive"] == true).toList(); // chỉ lấy active
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getActiveBanners(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(
            height: 180,
            child: Center(child: Text("Không có banner nào")),
          );
        }

        final banners = snapshot.data!;

        return Column(
          children: [
            CarouselSlider(
              items: banners.map((b) {
                return GestureDetector(
                  onTap: () {
                    final link = b['link'];
                    if (link != null && link.toString().isNotEmpty) {
                      // Mở link nếu có — có thể dùng url_launcher
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      b['imageUrl'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                            child: Icon(Icons.broken_image,
                                color: Colors.grey)),
                      ),
                    ),
                  ),
                );
              }).toList(),
              carouselController: _controller,
              options: CarouselOptions(
                autoPlay: true,
                enlargeCenterPage: true,
                aspectRatio: 16 / 9,
                viewportFraction: 0.9,
                onPageChanged: (index, reason) {
                  setState(() => _current = index);
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: banners.asMap().entries.map((entry) {
                return GestureDetector(
                  onTap: () => _controller.animateToPage(entry.key),
                  child: Container(
                    width: _current == entry.key ? 12.0 : 8.0,
                    height: _current == entry.key ? 12.0 : 8.0,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _current == entry.key
                          ? Colors.pink
                          : Colors.grey.shade400,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}
