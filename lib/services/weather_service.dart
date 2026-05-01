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
    String recommendation = "";
    if (temp < 15) {
      recommendation = "It's chilly outside ($temp°C)! We recommend a hot, creamy Hot Chocolate or a Warm Latte to keep you cozy.";
    } else if (condition.toLowerCase().contains('rain')) {
      recommendation = "Rainy days call for a strong Espresso or a cozy Mocha. Perfect for watching the rain from our window!";
    } else if (temp > 25) {
      recommendation = "It's a hot day ($temp°C)! Cool down with our Signature Iced Coffee or a refreshingly cold Cold Brew.";
    } else {
      recommendation = "Perfect weather for a classic Cappuccino! It's the ideal balance of espresso and foam for a day like today.";
    }
    return recommendation;
  }
}
