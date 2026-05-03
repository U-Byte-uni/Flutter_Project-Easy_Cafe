import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherService {
  final String _apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';
  
  // Fixed: Hardcoded coordinates for Jauharabad
  static const double _jauharabadLat = 32.2902;
  static const double _jauharabadLon = 72.2818;
  
  WeatherService() {
    if (_apiKey.isEmpty) {
      print('⚠️ WARNING: OPENWEATHER_API_KEY is missing from .env file');
    }
  }

  // Fixed: Method specifically for Jauharabad that guarantees no null values
  Future<Map<String, dynamic>> getJauharabadWeather() async {
    if (_apiKey.isEmpty) {
      throw Exception('API key is missing');
    }
    
    final url = 'https://api.openweathermap.org/data/2.5/weather?lat=$_jauharabadLat&lon=$_jauharabadLon&appid=$_apiKey&units=metric';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        // Fixed: Explicitly set the city name to avoid null
        data['name'] = 'Jauharabad';
        // Fixed: Ensure description exists
        if (data['weather'][0]['description'] == null) {
          data['weather'][0]['description'] = data['weather'][0]['main'] ?? 'clear sky';
        }
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key');
      } else {
        throw Exception('Failed to load weather (Status code: ${response.statusCode})');
      }
    } catch (e) {
      print('Weather API error: $e');
      rethrow;
    }
  }

  // Fixed: Modified to handle Jauharabad properly
  Future<Map<String, dynamic>> getCurrentWeather(String city) async {
    if (_apiKey.isEmpty) {
      throw Exception('API key is missing');
    }
    
    // Fixed: If city is Jauharabad (case insensitive), use the special method
    if (city.toLowerCase() == 'jauharabad') {
      return await getJauharabadWeather();
    }
    
    final encodedCity = Uri.encodeComponent(city);
    final url = 'https://api.openweathermap.org/data/2.5/weather?q=$encodedCity&appid=$_apiKey&units=metric';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('City "$city" not found');
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key');
      } else {
        throw Exception('Failed to load weather (Status code: ${response.statusCode})');
      }
    } catch (e) {
      print('Weather API error: $e');
      rethrow;
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