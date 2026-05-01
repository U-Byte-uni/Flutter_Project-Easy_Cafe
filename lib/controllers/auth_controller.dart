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

  Map<String, dynamic>? _profile;
  Map<String, dynamic>? get profile => _profile;

  AuthController() {
    _user = _supabaseService.currentUser;
    if (_user != null) {
      loadProfile();
    }
  }

  Future<void> loadProfile() async {
    try {
      _profile = await _supabaseService.getProfile();
      notifyListeners();
    } catch (e) {
      debugPrint("Profile context: $e");
    }
  }

  Future<void> updateProfile(String fullName, String? avatarUrl) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabaseService.updateProfile(fullName, avatarUrl);
      await loadProfile();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePassword(String newPassword) async {
    await Supabase.instance.client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
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
