import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/cafe_controller.dart';
import '../widgets/product_card.dart';
import '../theme/app_theme.dart';
import 'product_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Favorites",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Consumer<CafeController>(
                  builder: (context, cafe, child) {
                    final favProducts = cafe.products.where((p) => cafe.isFavorite(p.id)).toList();

                    if (favProducts.isEmpty) {
                      return const Center(
                        child: Text(
                          'No favorites yet.',
                          style: TextStyle(color: AppTheme.secondaryTextColor),
                        ),
                      );
                    }
                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                      ),
                      itemCount: favProducts.length,
                      itemBuilder: (context, index) {
                        return ProductCard(
                          product: favProducts[index],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailScreen(product: favProducts[index]),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
