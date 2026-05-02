import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/ai_service.dart';
import '../controllers/cart_controller.dart';
import '../controllers/cafe_controller.dart';
import '../theme/app_theme.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final AIService _aiService = AIService();
  String _aiDescription = "";
  bool _isLoadingDescription = true;
  String _selectedSize = 'M';

  @override
  void initState() {
    super.initState();
    _generateAIDescription();
  }

  Future<void> _generateAIDescription() async {
    try {
      final desc = await _aiService.getProductDescription(widget.product);
      setState(() {
        _aiDescription = desc;
        _isLoadingDescription = false;
      });
    } catch (e) {
      setState(() {
        _aiDescription = widget.product.description;
        _isLoadingDescription = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.5,
            child: Image.network(
              widget.product.imageUrl,
              fit: BoxFit.cover,
            ),
          ),
          // Back Button and Favorite
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black26,
                    padding: const EdgeInsets.only(left: 8),
                  ),
                ),
                IconButton(
                  onPressed: () => context.read<CafeController>().toggleFavorite(widget.product.id),
                  icon: Consumer<CafeController>(
                    builder: (context, cafe, _) {
                      final isFav = cafe.isFavorite(widget.product.id);
                      return Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : Colors.white,
                      );
                    },
                  ),
                  style: IconButton.styleFrom(backgroundColor: Colors.black26),
                ),
              ],
            ),
          ),
          // Content Container
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.6,
              padding: const EdgeInsets.all(25),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.name,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "With ${widget.product.roastedLevel}",
                            style: const TextStyle(color: AppTheme.secondaryTextColor),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: AppTheme.primaryColor, size: 20),
                            const SizedBox(width: 5),
                            Text(
                              widget.product.rating.toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  const Text("Description", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: _isLoadingDescription
                          ? const Center(child: LinearProgressIndicator())
                          : Text(
                              _aiDescription,
                              style: const TextStyle(color: Colors.white70, height: 1.5),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("Size", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: ['S', 'M', 'L'].map((size) {
                      final isSelected = _selectedSize == size;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedSize = size),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 52,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryColor : AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryColor : Colors.white24,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            size,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppTheme.secondaryTextColor,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Price", style: TextStyle(color: AppTheme.secondaryTextColor)),
                          Text(
                            "\$ ${widget.product.price.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.6,
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<CartController>().addItem(widget.product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${widget.product.name} added to cart!'),
                                duration: const Duration(seconds: 2),
                                action: SnackBarAction(
                                  label: 'View',
                                  onPressed: () {
                                    // Normally you'd navigate to cart screen
                                  },
                                ),
                              ),
                            );
                          },
                          child: const Text("Add to Cart"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
