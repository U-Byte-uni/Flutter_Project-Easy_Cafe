import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/ai_service.dart';
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
                  onPressed: () {},
                  icon: const Icon(Icons.favorite_border, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: Colors.black26),
                ),
              ],
            ),
          ),
          // Content Container
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.55,
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
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['S', 'M', 'L'].map((size) {
                      final isSelected = _selectedSize == size;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedSize = size),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.25,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.transparent : AppTheme.cardColor,
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              size,
                              style: TextStyle(
                                color: isSelected ? AppTheme.primaryColor : AppTheme.secondaryTextColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),
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
                          onPressed: () {},
                          child: const Text("Buy Now"),
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
