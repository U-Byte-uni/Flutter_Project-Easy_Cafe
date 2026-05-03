import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../models/category.dart';

class SupabaseService {
  final _client = Supabase.instance.client;

  // Authentication
  Future<AuthResponse> signUp(String email, String password, {String? fullName}) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;

  // Database - Profiles
  Future<Map<String, dynamic>> getProfile() async {
    final user = currentUser;
    if (user == null) throw 'User not authenticated';
    return await _client.from('profiles').select().eq('id', user.id).single();
  }

  Future<void> updateProfile(String fullName, String? avatarUrl) async {
    final user = currentUser;
    if (user == null) throw 'User not authenticated';
    await _client.from('profiles').upsert({
      'id': user.id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // Database - Orders
  Future<List<Map<String, dynamic>>> getOrders() async {
    final user = currentUser;
    if (user == null) throw 'User not authenticated';
    return await _client
        .from('orders')
        .select('*, order_items(*, products(*))')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
  }

  Future<void> createOrder(double total, List<Map<String, dynamic>> items) async {
    final user = currentUser;
    if (user == null) throw 'User not authenticated';
    
    final order = await _client.from('orders').insert({
      'user_id': user.id,
      'total_price': total,
      'status': 'Confirmed',
    }).select().single();

    final orderItems = items.map((item) => {
      'order_id': order['id'],
      'product_id': item['product_id'],
      'quantity': item['quantity'],
      'price': item['price'],
    }).toList();

    await _client.from('order_items').insert(orderItems);
  }

  // Database - Favorites
  Future<void> toggleFavorite(int productId) async {
    final user = currentUser;
    if (user == null) throw 'User not authenticated';
    
    final existing = await _client
        .from('favorites')
        .select()
        .eq('user_id', user.id)
        .eq('product_id', productId)
        .maybeSingle();

    if (existing != null) {
      await _client.from('favorites').delete().eq('id', existing['id']);
    } else {
      await _client.from('favorites').insert({
        'user_id': user.id,
        'product_id': productId,
      });
    }
  }

  Future<List<int>> getFavorites() async {
    final user = currentUser;
    if (user == null) return [];
    final response = await _client.from('favorites').select('product_id').eq('user_id', user.id);
    return (response as List).map((f) => f['product_id'] as int).toList();
  }

  Future<void> clearAllFavorites() async {
    final user = currentUser;
    if (user == null) throw 'User not authenticated';
    await _client.from('favorites').delete().eq('user_id', user.id);
  }

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
