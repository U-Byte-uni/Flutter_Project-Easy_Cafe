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

  List<Product> get products => _selectedCategoryId == 0 
      ? _products 
      : _products.where((p) => p.categoryId == _selectedCategoryId).toList();
      
  List<Category> get categories => _categories;
  int get selectedCategoryId => _selectedCategoryId;
  bool get isLoading => _isLoading;

  Future<void> fetchData() async {
    _isLoading = true;
    notifyListeners();
    try {
      _products = await _supabaseService.getProducts();
      _categories = await _supabaseService.getCategories();
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
