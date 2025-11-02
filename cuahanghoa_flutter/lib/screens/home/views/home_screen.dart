import 'package:flutter/material.dart';
import 'package:cuahanghoa_flutter/constants.dart';

import 'components/offer_carousel_and_categories.dart';
import 'components/all_products_list.dart.dart';
import 'components/most_popular.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Carousel & Danh mục
            const SliverToBoxAdapter(
              child: OffersCarouselAndCategories(),
            ),

            //  Tất cả sản phẩm (Firebase)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: defaultPadding),
                child: AllProductsList(),
              ),
            ),

            //  Phổ biến (Firebase)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: defaultPadding),
                child: MostPopular(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
