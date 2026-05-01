import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../models/category.dart';

class SupabaseService {
  final _client = Supabase.instance.client;

  // Authentication
  Future<AuthResponse> signUp(String email, String password) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;

  // Database - Products
  Future<List<Product>> getProducts() async {
    final response = await _client.from('products').select();
    return (response as List).map((item) => Product.fromJson(item)).toList();
  }

  // Database - Categories
  Future<List<Category>> getCategories() async {
    final response = await _client.from('categories').select();
    return (response as List).map((item) => Category.fromJson(item)).toList();
  }
}
