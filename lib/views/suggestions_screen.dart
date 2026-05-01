import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';

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
      body: SafeArea(
        child: Padding(
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
              // We could add a filtered product horizontal list here
            ],
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
