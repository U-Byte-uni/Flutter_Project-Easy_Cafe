import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../services/supabase_service.dart';

class CafeController extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  List<Product> _products = [];
  List<Category> _categories = [];
  int _selectedCategoryId = 0; // 0 for 'All'
  bool _isLoading = false;
  List<int> _favoriteIds = [];

  String _searchQuery = "";

  List<Product> get products {
    List<Product> filtered = _products;
    if (_selectedCategoryId != 0) {
      filtered = filtered.where((p) => p.categoryId == _selectedCategoryId).toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) => 
        p.name.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    return filtered;
  }
      
  List<Category> get categories => _categories;
  int get selectedCategoryId => _selectedCategoryId;
  bool get isLoading => _isLoading;
  List<int> get favoriteIds => _favoriteIds;

  bool isFavorite(int productId) => _favoriteIds.contains(productId);

  Future<void> toggleFavorite(int productId) async {
    try {
      await _supabaseService.toggleFavorite(productId);
      if (_favoriteIds.contains(productId)) {
        _favoriteIds.remove(productId);
      } else {
        _favoriteIds.add(productId);
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error toggling favorite: $e");
    }
  }

  Future<void> clearAllFavorites() async {
    try {
      await _supabaseService.clearAllFavorites();
      _favoriteIds.clear();
      notifyListeners();
    } catch (e) {
      debugPrint("Error clearing favorites: $e");
    }
  }

  void searchProducts(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchData() async {
    _isLoading = true;
    notifyListeners();
    try {
      _products = await _supabaseService.getProducts();
      _categories = await _supabaseService.getCategories();
      _favoriteIds = await _supabaseService.getFavorites();
    } catch (e) {
      debugPrint("Error fetching data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCategory(int id) {
    _selectedCategoryId = id;
    notifyListeners();
  }
}
