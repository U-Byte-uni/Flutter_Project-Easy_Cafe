import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class AIService {
  final String _baseUrl = "https://openrouter.ai/api/v1/chat/completions";
  
  // ✅ Using the special free router that auto-selects available free models
  final String _primaryModel = "openrouter/free";
  
  String get _apiKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';

  bool _isCafeRelated(String prompt, List<Product> menu) {
    final text = prompt.toLowerCase();
    const strongKeywords = [
      'easy cafe',
      'cafe',
      'coffee',
      'menu',
      'drink',
      'snack',
      'snacks',
      'pastry',
      'pastries',
      'dessert',
      'cake',
      'cookie',
      'muffin',
      'latte',
      'espresso',
      'cappuccino',
      'flat white',
      'mocha',
      'cart',
      'checkout',
      'favorite',
      'order',
    ];
    const allowedPhrases = [
      'show menu',
      'show the menu',
      'give menu',
      'give the menu',
      'menu items',
      'what is on the menu',
      "what's on the menu",
      'check price',
      'check prices',
      'tell cheapest',
      'cheapest',
      'best',
      "what's hot",
      'whats hot',
      'hot items',
      'hot picks',
      'hot offer',
      'hot offers',
      'offer',
      'offers',
      'deal',
      'discount',
      'surprise me',
      'snack',
      'snacks',
      'pastry',
      'pastries',
      'dessert',
      'cake',
      'cookie',
      'muffin',
      'best sellers',
      'best seller',
      'popular',
      'top picks',
      'top pick',
      'recommend',
      'recommendation',
      'suggest',
      'suggestion',
      'price',
      'cost',
    ];
    if (strongKeywords.any(text.contains)) return true;
    if (allowedPhrases.any(text.contains)) return true;
    for (final product in menu) {
      if (text.contains(product.name.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  bool _isOrderActionRequest(String prompt) {
    final text = prompt.toLowerCase();
    const phrases = [
      'order for me',
      'place order',
      'place an order',
      'buy for me',
      'purchase for me',
      'checkout for me',
      'order this for me',
      'add to cart for me',
      'make an order',
      'can you order',
      'can you place an order',
      'can you buy',
    ];
    return phrases.any(text.contains);
  }

  bool _isMenuRequest(String prompt) {
    final text = prompt.toLowerCase();
    const phrases = [
      'menu',
      'show menu',
      'show the menu',
      'give menu',
      'give the menu',
      'menu items',
      'what is on the menu',
      "what's on the menu",
    ];
    return phrases.any(text.contains);
  }

  bool _isHotRequest(String prompt) {
    final text = prompt.toLowerCase();
    const phrases = [
      "what's hot",
      'whats hot',
      'hot items',
      'hot picks',
      'best sellers',
      'best seller',
      'popular',
      'top picks',
      'top pick',
    ];
    return phrases.any(text.contains);
  }

  bool _isSurpriseRequest(String prompt) {
    final text = prompt.toLowerCase();
    const phrases = ['surprise me', 'surprise', 'random pick'];
    return phrases.any(text.contains);
  }

  bool _isSnackRequest(String prompt) {
    final text = prompt.toLowerCase();
    const phrases = [
      'snack',
      'snacks',
      'pastry',
      'pastries',
      'dessert',
      'cake',
      'cookie',
      'muffin',
    ];
    return phrases.any(text.contains);
  }

  String _localMenuResponse(List<Product> menu) {
    if (menu.isEmpty) {
      return "Menu is still loading. Please try again in a moment.";
    }
    final items = menu.take(6).map(
      (p) => "• ☕ ${p.name} — \$${p.price.toStringAsFixed(2)}",
    ).join('\n');
    return "Here is our menu:\n$items";
  }

  String _localHotResponse(List<Product> menu) {
    if (menu.isEmpty) {
      return "I do not have the menu yet. Please try again in a moment.";
    }
    final sorted = List<Product>.from(menu)
      ..sort((a, b) => b.rating.compareTo(a.rating));
    final picks = sorted.take(3).map((p) => p.name).join(', ');
    return "Popular picks right now: $picks.";
  }

  String _localSurpriseResponse(List<Product> menu) {
    if (menu.isEmpty) {
      return "I do not have the menu yet. Please try again in a moment.";
    }
    final pick = menu.first;
    return "Surprise pick: ${pick.name} (\$${pick.price.toStringAsFixed(2)}).";
  }

  String _localSnackResponse(List<Product> menu) {
    if (menu.isEmpty) {
      return "Menu is still loading. Please try again in a moment.";
    }
    final snacks = menu.where((p) =>
      p.categoryId != 1 &&
      p.categoryId != 2 &&
      p.categoryId != 3 &&
      p.categoryId != 4
    ).toList();
    if (snacks.isEmpty) {
      return "We do not have snack items listed right now. Try our coffee menu instead.";
    }
    final items = snacks.take(6).map(
      (p) => "• 🍰 ${p.name} — \$${p.price.toStringAsFixed(2)}",
    ).join('\n');
    return "Here are our snacks:\n$items";
  }

  String _fallbackResponse(String prompt, List<Product> menu) {
    if (_isMenuRequest(prompt)) return _localMenuResponse(menu);
    if (_isHotRequest(prompt)) return _localHotResponse(menu);
    if (_isSurpriseRequest(prompt)) return _localSurpriseResponse(menu);
    if (_isSnackRequest(prompt)) return _localSnackResponse(menu);
    return "I am having trouble connecting right now. You can ask about the menu, prices, or offers.";
  }

  Future<String> getWeatherRecommendation({
    required double temp,
    required String condition,
    required List<Product> menu,
    required List<Product> picks,
  }) async {
    if (_apiKey.isEmpty) {
      return "I cannot reach the AI right now.";
    }

    if (picks.isEmpty) {
      return "No products available for a recommendation.";
    }

    final pickNames = picks.map((p) => p.name).join(', ');
    final systemPrompt =
        "You are the Easy Cafe weather assistant. You must respond with exactly two short lines, no bullets. "
        "Explain why the selected items fit the current weather.";
    final userPrompt =
        "Weather: ${temp.round()}°C, ${condition.toLowerCase()}. "
        "Selected items: $pickNames. "
        "Write two short lines (two sentences on separate lines).";

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          "Authorization": "Bearer $_apiKey",
          "Content-Type": "application/json",
          "HTTP-Referer": "http://localhost",
          "X-Title": "Easy Cafe App",
        },
        body: jsonEncode({
          "model": _primaryModel,
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": userPrompt}
          ],
          "max_tokens": 120,
          "temperature": 0.6,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content']?.toString().trim();
        if (content != null && content.isNotEmpty) {
          return content;
        }
      }
    } catch (e) {
      debugPrint("Weather recommendation error: $e");
    }

    final fallbackPick = picks.first.name;
    final otherPick = picks.length > 1 ? picks[1].name : picks.first.name;
    return "$fallbackPick fits the ${condition.toLowerCase()} weather at ${temp.round()}°C.\n"
        "$otherPick adds a balanced, comforting pairing for today.";
  }

  // Feature 1: Chatbot that answers questions about menu
  Future<String> getChatResponse(String userPrompt, List<Product> menu) async {
    if (_apiKey.isEmpty) {
      debugPrint("❌ API key missing");
      return "AI Service is not configured. Please check app settings.";
    }

    if (!_isCafeRelated(userPrompt, menu)) {
      return "I can only help with Easy Cafe questions like menu items, prices, orders, or app features.";
    }

    if (_isOrderActionRequest(userPrompt)) {
      return "I can't perform that specified task. You can place orders directly in the app using the cart.";
    }

    if (_isMenuRequest(userPrompt)) {
      return _localMenuResponse(menu);
    }

    if (_isHotRequest(userPrompt)) {
      return _localHotResponse(menu);
    }

    if (_isSurpriseRequest(userPrompt)) {
      return _localSurpriseResponse(menu);
    }

    if (_isSnackRequest(userPrompt)) {
      return _localSnackResponse(menu);
    }

    final menuDetails = menu.map((p) => "${p.name}: \$${p.price.toStringAsFixed(2)}").join(", ");
    final systemPrompt = "You are an AI assistant for Easy Cafe. Here is our current menu: $menuDetails. "
        "Answer user questions about the menu, lowest cost items, or premium items. "
        "Be friendly and helpful. If asked for something not on the menu, politely mention what we do have. "
        "If the user asks about anything unrelated to Easy Cafe, respond: 'I can only help with Easy Cafe questions.'";
    
    try {
      debugPrint("🤖 Sending request to OpenRouter with model: $_primaryModel");
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          "Authorization": "Bearer $_apiKey",
          "Content-Type": "application/json",
          "HTTP-Referer": "http://localhost", 
          "X-Title": "Easy Cafe App",
        },
        body: jsonEncode({
          "model": _primaryModel,
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": userPrompt}
          ],
          "max_tokens": 500,
          "temperature": 0.7,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        debugPrint("✅ AI Response received (${content.length} chars)");
        return content ?? "Sorry, I couldn't process that.";
      } else {
        debugPrint("❌ OpenRouter Error (${response.statusCode}): ${response.body}");
        
        // Try to parse error message from OpenRouter
        try {
          final errorData = jsonDecode(response.body);
          final errorMsg = errorData['error']['message'] ?? 'Unknown error';
          return "AI Error: $errorMsg";
        } catch (_) {
          return _fallbackResponse(userPrompt, menu);
        }
      }
    } catch (e) {
     
      debugPrint("❌ AI Service request failed: $e");
        if (e is SocketException) {
          return "It seems like there's a network issue. Please check your connection and try again.";
        } 
        return _fallbackResponse(userPrompt, menu);
    }
  }

  // Feature 2: Description of the item when clicked
  Future<String> getProductDescription(Product product) async {
    if (_apiKey.isEmpty) {
      debugPrint("⚠️ Using fallback description (no API key)");
      return product.description;
    }

    final prompt = "Generate a mouth-watering, professional description for a coffee shop item named '${product.name}' which costs \$${product.price.toStringAsFixed(2)}. "
        "The description should be between 3 to 5 full sentences. "
        "Mention it is a signature item at Easy Cafe. Focus on the aroma, taste, and experience.";
    
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          "Authorization": "Bearer $_apiKey",
          "Content-Type": "application/json",
          "HTTP-Referer": "http://localhost",
          "X-Title": "Easy Cafe App",
        },
        body: jsonEncode({
          "model": _primaryModel,
          "messages": [
            {"role": "system", "content": "You are a professional food copywriter specializing in coffee shop descriptions. Be concise and engaging."},
            {"role": "user", "content": prompt}
          ],
          "max_tokens": 250,
          "temperature": 0.8,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final description = data['choices'][0]['message']['content']?.toString().trim();
        if (description != null && description.isNotEmpty) {
          return description;
        }
      }
      return product.description; // Fallback
    } catch (e) {
      debugPrint("❌ Description generation failed: $e");
      return product.description; // Fallback
    }
  }

  // Optional: Test method to verify configuration
  Future<bool> testConfiguration() async {
    debugPrint("🧪 Testing OpenRouter configuration...");
    
    if (_apiKey.isEmpty) {
      debugPrint("❌ No API key found in .env file");
      return false;
    }
    
    debugPrint("✅ API key found (length: ${_apiKey.length})");
    debugPrint("📡 Testing with model: $_primaryModel");
    
    try {
      final testResponse = await getChatResponse(
        "Just say 'OK' if you can hear me", 
        [] // Empty menu for test
      );
      
      debugPrint("📨 Test response: $testResponse");
      final success = testResponse.isNotEmpty && 
                      !testResponse.contains("not configured") &&
                      !testResponse.contains("Error");
      
      if (success) {
        debugPrint("✅ AI Service is working correctly!");
      } else {
        debugPrint("❌ AI Service test failed: $testResponse");
      }
      
      return success;
    } catch (e) {
      debugPrint("❌ Test failed with exception: $e");
      return false;
    }
  }
}