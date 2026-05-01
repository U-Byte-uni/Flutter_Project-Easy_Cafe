import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/product.dart';

class AIService {
  late final GenerativeModel _model;

  AIService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    // Use gemini-1.5-flash-latest to ensure it's found by the API
    _model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: apiKey);
  }

  // Feature 1: Chatbot that answers questions about menu
  Future<String> getChatResponse(String userPrompt, List<Product> menu) async {
    final menuDetails = menu.map((p) => "${p.name}: \$${p.price}").join(", ");
    final systemPrompt = "You are an AI assistant for Easy Cafe. Here is our current menu: $menuDetails. "
        "Answer user questions about the menu, lowest cost items, or premium items. "
        "Be friendly and helpful. If asked for something not on the menu, politely mention what we do have.";
    
    final content = [Content.text("$systemPrompt\nUser: $userPrompt")];
    final response = await _model.generateContent(content);
    return response.text ?? "Sorry, I couldn't process that.";
  }

  // Feature 2: Description of the item when clicked (Updated to 3-5 lines)
  Future<String> getProductDescription(Product product) async {
    final prompt = "Generate a mouth-watering, professional description for a coffee shop item named '${product.name}' which costs \$${product.price}. "
        "The description should be between 3 to 5 full sentences. "
        "Mention it is a signature item at Easy Cafe. Focus on the aroma, taste, and experience.";
    
    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    return response.text?.trim() ?? product.description;
  }
}
