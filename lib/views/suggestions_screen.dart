import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../controllers/cafe_controller.dart';
import '../models/product.dart';
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
  Map<String, dynamic>? _weatherData;
  String _recommendation = "Loading recommendation...";
  bool _isLoading = true;
  double? _temperature;
  String _weatherCondition = 'Clear';

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

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    final location = dotenv.env['DEFAULT_LOCATION'] ?? 'London';
    try {
      final data = await _weatherService.getCurrentWeather(location);
      final temp = (data['main']['temp'] as num).toDouble();
      final condition = data['weather'][0]['main'];
      
      setState(() {
        _weatherData = data;
        _temperature = temp;
        _weatherCondition = condition;
        _recommendation = _weatherService.getCoffeeRecommendation(temp, condition);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Weather Fetch Error: $e");
      setState(() {
        _recommendation = "Could not fetch weather. Perfect time for a coffee anyway!";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const Text(
                "Weather\nSuggestions",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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
                          _getWeatherIcon(_weatherData?['weather'][0]['main'] ?? 'Clear'),
                          size: 60,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "${_weatherData?['main']['temp']?.round() ?? '--'}°C in ${dotenv.env['DEFAULT_LOCATION']}",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _weatherData?['weather'][0]['description']?.toUpperCase() ?? 'CLEAR SKY',
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
