import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cuahanghoa_flutter/constants.dart';
import 'package:cuahanghoa_flutter/route/route_constants.dart';
import 'banner_carousel.dart';

class OffersCarouselAndCategories extends StatelessWidget {
  const OffersCarouselAndCategories({super.key});

  Stream<List<Map<String, dynamic>>> getCategories() {
    final ref = FirebaseDatabase.instance.ref('categories');
    return ref.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return <Map<String, dynamic>>[];
      final map = data as Map<dynamic, dynamic>;
      return map.values.map((e) {
        return {
          "name": e['name'] ?? 'Không tên',
          "icon": e['icon'] ?? 'category',
        };
      }).toList();
    });
  }

  IconData _getIconByName(String name) {
    switch (name) {
      case 'local_florist':
        return Icons.local_florist;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'favorite':
        return Icons.favorite;
      case 'home':
        return Icons.home;
      case 'emoji_events':
        return Icons.emoji_events;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: defaultPadding),
          child: BannerCarousel(), //Dùng banner động
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Text(
            "Danh mục",
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        const SizedBox(height: defaultPadding / 2),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: getCategories(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 90,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox(
                height: 90,
                child: Center(child: Text("Không có danh mục")),
              );
            }
            final categories = snapshot.data!;
            return SizedBox(
              height: 90,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: defaultPadding),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        productByCategoryScreenRoute,
                        arguments: category['name'],
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Icon(
                            _getIconByName(category['icon']),
                            color: Theme.of(context).primaryColor,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 65,
                          child: Text(
                            category['name'],
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
