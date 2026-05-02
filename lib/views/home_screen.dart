import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/cafe_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/category_item.dart';
import '../widgets/product_card.dart';
import '../theme/app_theme.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<CafeController>().fetchData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.apps, color: AppTheme.secondaryTextColor),
                  ),
                  Consumer<AuthController>(
                    builder: (context, auth, _) {
                      final profile = auth.profile;
                      final avatarUrl = profile?['avatar_url'] as String?;
                      return CircleAvatar(
                        backgroundColor: AppTheme.primaryColor,
                        backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty == true) 
                          ? NetworkImage(avatarUrl) 
                          : null,
                        child: (avatarUrl == null || avatarUrl.isEmpty == true)
                          ? const Icon(Icons.person, color: Colors.black)
                          : null,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                "Find the best\ncoffee for you",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextField(
                onChanged: (value) {
                  context.read<CafeController>().searchProducts(value);
                },
                decoration: InputDecoration(
                  hintText: "Find Your Coffee...",
                  prefixIcon: const Icon(Icons.search, color: AppTheme.secondaryTextColor),
                  filled: true,
                  fillColor: AppTheme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Consumer<CafeController>(
                builder: (context, cafe, child) {
                  return SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: cafe.categories.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return CategoryItem(
                            title: "All",
                            isSelected: cafe.selectedCategoryId == 0,
                            onTap: () => cafe.selectCategory(0),
                          );
                        }
                        final cat = cafe.categories[index - 1];
                        return CategoryItem(
                          title: cat.name,
                          isSelected: cafe.selectedCategoryId == cat.id,
                          onTap: () => cafe.selectCategory(cat.id),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Consumer<CafeController>(
                  builder: (context, cafe, child) {
                    if (cafe.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (cafe.products.isEmpty) {
                      return const Center(child: Text("No products found."));
                    }
                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                      ),
                      itemCount: cafe.products.length,
                      itemBuilder: (context, index) {
                        return ProductCard(
                          product: cafe.products[index],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailScreen(product: cafe.products[index]),
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
