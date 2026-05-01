import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherService {
  final String _apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';

  Future<Map<String, dynamic>> getCurrentWeather(String city) async {
    final url = 'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$_apiKey&units=metric';
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load weather');
      }
    } catch (e) {
      return {'main': {'temp': 25}, 'weather': [{'main': 'Clear'}]}; // Mock fallback
    }
  }

  String getCoffeeRecommendation(double temp, String condition) {
    if (temp < 15) {
      return "It's chilly outside ($temp°C)! We recommend a hot, creamy Hot Chocolate or a Warm Latte.";
    } else if (condition.toLowerCase().contains('rain')) {
      return "Rainy days call for a strong Espresso or a cozy Mocha.";
    } else if (temp > 25) {
      return "It's a hot day ($temp°C)! Cool down with our Signature Iced Coffee or a Cold Brew.";
    } else {
      return "Perfect weather for a classic Cappuccino!";
    }
  }
}
