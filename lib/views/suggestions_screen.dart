import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../controllers/cafe_controller.dart';
import '../models/product.dart';
import '../services/ai_service.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  final WeatherService _weatherService = WeatherService();
  final AIService _aiService = AIService();
  String _recommendation = "Loading recommendation...";
  bool _isLoading = true;
  double? _temperature;
  String _weatherCondition = 'Clear';
  bool _isAiLoading = false;
  bool _showAiRecommendations = false;
  String _aiReason = '';
  List<Product> _aiProducts = [];

  List<Product> _getWeatherProducts(List<Product> allProducts) {
    if (_temperature == null) return allProducts.take(5).toList();
    // Category IDs from the Supabase schema:
    // 1 = Cappuccino, 2 = Espresso, 3 = Latte, 4 = Flat White
    if (_temperature! < 15) {
      // Cold: highlight warm drinks — Cappuccino (1) & Latte (3)
      final warm = allProducts.where((p) => p.categoryId == 1 || p.categoryId == 3).toList();
      return warm.isNotEmpty ? warm : allProducts.take(5).toList();
    } else if (_weatherCondition.toLowerCase().contains('rain')) {
      // Rainy: highlight strong coffee — Espresso (2)
      final strong = allProducts.where((p) => p.categoryId == 2).toList();
      return strong.isNotEmpty ? strong : allProducts.take(5).toList();
    } else if (_temperature! > 25) {
      // Hot: prefer Flat White (4) or any product with "cold"/"ice"/"iced" in name
      final cold = allProducts
          .where((p) =>
              p.categoryId == 4 ||
              p.name.toLowerCase().contains('cold') ||
              p.name.toLowerCase().contains('ice') ||
              p.name.toLowerCase().contains('iced'))
          .toList();
      return cold.isNotEmpty ? cold : allProducts.take(5).toList();
    }
    // Pleasant weather: top-rated products
    final sorted = List<Product>.from(allProducts)
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(5).toList();
  }

  List<Product> _getBeverages(List<Product> allProducts) {
    return allProducts.where((product) =>
      product.categoryId == 1 ||
      product.categoryId == 2 ||
      product.categoryId == 3 ||
      product.categoryId == 4
    ).toList();
  }

  List<Product> _getSnacks(List<Product> allProducts) {
    return allProducts.where((product) =>
      product.categoryId != 1 &&
      product.categoryId != 2 &&
      product.categoryId != 3 &&
      product.categoryId != 4
    ).toList();
  }

  Future<void> _consultAi(List<Product> allProducts) async {
    if (_temperature == null || allProducts.isEmpty) return;

    final beverages = _getBeverages(allProducts);
    final snacks = _getSnacks(allProducts);

    final weatherPicks = _getWeatherProducts(allProducts);
    final coffeePick = weatherPicks.firstWhere(
      (p) => beverages.contains(p),
      orElse: () => beverages.isNotEmpty ? beverages.first : allProducts.first,
    );

    Product? snackPick = snacks.isNotEmpty ? snacks.first : null;

    final picks = <Product>[
      coffeePick,
      if (snackPick != null && snackPick.id != coffeePick.id) snackPick,
    ];

    if (snackPick == null) {
      final fallback = allProducts.firstWhere(
        (p) => p.id != coffeePick.id,
        orElse: () => allProducts.first,
      );
      if (!picks.any((p) => p.id == fallback.id)) {
        picks.add(fallback);
      }
    }

    setState(() {
      _isAiLoading = true;
      _showAiRecommendations = true;
      _aiProducts = picks;
      _aiReason = '';
    });

    final tempLabel = (_temperature ?? 0).round();
    final coffeeName = coffeePick.name;
    final snackName = snackPick?.name ?? (picks.length > 1 ? picks[1].name : 'a snack');
    try {
      final response = await _aiService.getWeatherRecommendation(
        temp: _temperature ?? 0,
        condition: _weatherCondition,
        menu: allProducts,
        picks: picks,
      );
      final lines = response
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      String reason;
      if (lines.length >= 2) {
        reason = "${lines[0]}\n${lines[1]}";
      } else {
        reason =
            "$coffeeName pairs well with ${_weatherCondition.toLowerCase()} weather at $tempLabel°C.\n"
            "$snackName balances the pick for a cozy, weather-matched treat.";
      }
      if (mounted) {
        setState(() {
          _aiReason = reason;
          _isAiLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiReason =
              "$coffeeName pairs well with ${_weatherCondition.toLowerCase()} weather at $tempLabel°C.\n"
              "$snackName balances the pick for a cozy, weather-matched treat.";
          _isAiLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    final location = dotenv.env['DEFAULT_LOCATION'] ?? 'Jauharabad';
    try {
      final data = await _weatherService.getCurrentWeather(location);
      
      // Safe extraction with fallback values
      final temp = (data['main']?['temp'] as num?)?.toDouble() ?? 25.0;
      final condition = data['weather']?[0]?['main'] ?? 'Clear';
      
      setState(() {
        _temperature = temp;
        _weatherCondition = condition;
        _recommendation = _weatherService.getCoffeeRecommendation(temp, condition);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Weather Fetch Error: $e");
      // Provide fallback data instead of just an error message
      setState(() {
        _temperature = 30.0;
        _weatherCondition = 'Clear';
        _recommendation = "☀️ Beautiful weather in Jauharabad! Try our refreshing Iced Latte or classic Cappuccino.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Weather\nSuggestions",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTheme.headingFontFamily,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: _isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            Icon(
                              _getWeatherIcon(_weatherCondition),
                              size: 60,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "${(_temperature ?? 30).round()}°C in Jauharabad",
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _weatherCondition.toUpperCase(),
                              style: const TextStyle(color: AppTheme.secondaryTextColor),
                            ),
                            const SizedBox(height: 20),
                            const Divider(color: Colors.white24),
                            const SizedBox(height: 20),
                            Text(
                              _recommendation,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16, height: 1.5),
                            ),
                          ],
                        ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.center,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => _consultAi(context.read<CafeController>().products),
                      icon: const Icon(Icons.auto_awesome, color: AppTheme.primaryColor),
                      label: const Text(
                        "Consult AI",
                        style: TextStyle(color: AppTheme.primaryColor),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.6)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  if (_showAiRecommendations) ...[
                    const SizedBox(height: 18),
                    const Text(
                      "AI Picks for this weather",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    if (_isAiLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      Text(
                        _aiReason,
                        style: const TextStyle(color: Colors.white70, height: 1.4),
                      ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _aiProducts.length,
                        itemBuilder: (context, index) {
                          return SizedBox(
                            width: 155,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: ProductCard(
                                product: _aiProducts[index],
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailScreen(
                                        product: _aiProducts[index],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                  const Text(
                    "Special for this weather",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Consumer<CafeController>(
                    builder: (context, cafe, _) {
                      final weatherProducts = _getWeatherProducts(cafe.products);
                      if (cafe.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (weatherProducts.isEmpty) {
                        return const Text(
                          'No products available.',
                          style: TextStyle(color: AppTheme.secondaryTextColor),
                        );
                      }
                      return SizedBox(
                        height: 220,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: weatherProducts.length,
                          itemBuilder: (context, index) {
                            return SizedBox(
                              width: 155,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: ProductCard(
                                  product: weatherProducts[index],
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductDetailScreen(
                                          product: weatherProducts[index],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    condition = condition.toLowerCase();
    if (condition.contains('cloud')) return Icons.cloud;
    if (condition.contains('rain')) return Icons.beach_access;
    if (condition.contains('clear')) return Icons.wb_sunny;
    return Icons.wb_cloudy_outlined;
  }
}