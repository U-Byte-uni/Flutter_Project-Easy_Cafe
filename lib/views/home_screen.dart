import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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
                  ClipOval(
                    child: Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
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
              const SizedBox(height: 20),
              
              // Cafe Title - Comic Sans MS, Bold, Bigger, Whitish color
              Text(
                "Easy Café",
                style: GoogleFonts.comicNeue(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: Colors.white.withOpacity(0.92),
                ),
              ),
              const SizedBox(height: 10),
              
              // Motto - Using Satisfy font (beautiful script font)
              Text(
                "Find the best\ncoffee for you",
                style: GoogleFonts.satisfy(
                  fontSize: 32,
                  height: 1.2,
                  color: AppTheme.primaryColor,
                  shadows: [
                    const Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 3,
                      color: Colors.black26,
                    ),
                  ],
                ),
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
                    
                    // Filter products into beverages and snacks
                    final beverages = cafe.products.where((product) => 
                      product.categoryId == 1 ||
                      product.categoryId == 2 ||
                      product.categoryId == 3 ||
                      product.categoryId == 4
                    ).toList();
                    
                    final snacks = cafe.products.where((product) => 
                      product.categoryId != 1 &&
                      product.categoryId != 2 &&
                      product.categoryId != 3 &&
                      product.categoryId != 4
                    ).toList();
                    
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (beverages.isNotEmpty) ...[
                            const Text(
                              "☕ Hot & Cold Beverages",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 15),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.7,
                                crossAxisSpacing: 15,
                                mainAxisSpacing: 15,
                              ),
                              itemCount: beverages.length,
                              itemBuilder: (context, index) {
                                return ProductCard(
                                  product: beverages[index],
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProductDetailScreen(product: beverages[index]),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 30),
                          ],
                          
                          if (snacks.isNotEmpty) ...[
                            const Text(
                              "🍰 Snacks & Pastries",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 15),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.7,
                                crossAxisSpacing: 15,
                                mainAxisSpacing: 15,
                              ),
                              itemCount: snacks.length,
                              itemBuilder: (context, index) {
                                return ProductCard(
                                  product: snacks[index],
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProductDetailScreen(product: snacks[index]),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ],
                      ),
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