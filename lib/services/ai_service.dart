import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/product.dart';

class AIService {
  late final GenerativeModel _model;

  AIService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
  }

  // Feature 1: Chatbot that answers questions about menu
  Future<String> getChatResponse(String userPrompt, List<Product> menu) async {
    final menuDetails = menu.map((p) => "${p.name}: \$${p.price}").join(", ");
    final systemPrompt = "You are an AI assistant for Easy Cafe. Here is our menu: $menuDetails. "
        "Answer user questions about the menu, lowest cost items, or premium items. Keep it short and friendly.";
    
    final content = [Content.text("$systemPrompt\nUser: $userPrompt")];
    final response = await _model.generateContent(content);
    return response.text ?? "Sorry, I couldn't process that.";
  }

  // Feature 2: Description of the item when clicked
  Future<String> getProductDescription(Product product) async {
    final prompt = "Generate a short, mouth-watering description for a coffee shop item named '${product.name}' which costs \$${product.price}. "
        "Mention it's available at Easy Cafe. Max 2 sentences.";
    
    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    return response.text ?? product.description;
  }
}
