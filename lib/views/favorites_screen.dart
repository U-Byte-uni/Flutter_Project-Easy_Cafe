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
    final canPop = Navigator.canPop(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (canPop)
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(Icons.arrow_back, size: 24),
                            ),
                          ),
                        const Text(
                          "Favorites",
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Consumer<CafeController>(
                      builder: (context, cafe, _) {
                        final hasFavs = cafe.products.any((p) => cafe.isFavorite(p.id));
                        if (!hasFavs) return const SizedBox.shrink();
                        return TextButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: AppTheme.cardColor,
                                title: const Text('Clear All Favorites'),
                                content: const Text(
                                  'Are you sure you want to remove all favorites?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text(
                                      'Clear All',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && context.mounted) {
                              await context.read<CafeController>().clearAllFavorites();
                            }
                          },
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                          label: const Text(
                            'Clear All',
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      },
                    ),
                  ],
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
      ),
    );
  }
}
