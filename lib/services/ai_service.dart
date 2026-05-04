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
      'check price',
      'check prices',
      'tell cheapest',
      'cheapest',
      'best',
      'hot offer',
      'hot offers',
      'offer',
      'offers',
      'deal',
      'discount',
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
          return "I'm having trouble thinking right now. Please try again later!";
        }
      }
    } catch (e) {
     
      debugPrint("❌ AI Service request failed: $e");
        if (e is SocketException) {
          return "It seems like there's a network issue. Please check your connection and try again.";
        } 
        return "Sorry, I'm having trouble connecting to my coffee sensors. Please try again!";
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