import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthController() {
    _user = _supabaseService.currentUser;
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabaseService.signIn(email, password);
      _user = response.user;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabaseService.signUp(email, password);
      _user = response.user;
      
      // Update the user's display name in metadata or profiles table
      if (_user != null) {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(data: {'full_name': name}),
        );
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _supabaseService.signOut();
    _user = null;
    notifyListeners();
  }
}
