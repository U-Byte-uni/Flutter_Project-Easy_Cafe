import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cafe_controller.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _avatarUrlController = TextEditingController();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthController>().profile;
    _nameController.text = profile?['full_name'] ?? '';
    _avatarUrlController.text = profile?['avatar_url'] ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.cardColor,
              child: Icon(Icons.camera_alt, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _avatarUrlController,
              decoration: const InputDecoration(
                labelText: 'Profile Picture URL',
                hintText: 'Paste an image link here',
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _updateProfile,
                child: _isUpdating 
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text('Save Changes'),
              ),
            ),
            const SizedBox(height: 30),
            const Divider(color: Colors.white10),
            const SizedBox(height: 10),
            _buildFavoritesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesSection() {
    return Consumer<CafeController>(
      builder: (context, cafe, child) {
        final favProducts = cafe.products.where((p) => cafe.isFavorite(p.id)).toList();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Account Management",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.red),
              title: const Text("Clear All Favorites"),
              subtitle: Text("${favProducts.length} items saved"),
              trailing: const Icon(Icons.chevron_right),
              onTap: favProducts.isEmpty ? null : () => _showClearFavoritesDialog(context, cafe),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.orange),
              title: const Text("Logout"),
              onTap: () async {
                await context.read<AuthController>().signOut();
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showClearFavoritesDialog(BuildContext context, CafeController cafe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text("Clear Favorites?"),
        content: const Text("This will remove all items from your favorites list."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              // We'll add a clearAllFavorites method to controller
              await cafe.clearAllFavorites();
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Clear", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfile() async {
    setState(() => _isUpdating = true);
    try {
      final auth = context.read<AuthController>();
      await auth.updateProfile(
        _nameController.text, 
        _avatarUrlController.text.isNotEmpty ? _avatarUrlController.text : null
      );
      if (_passwordController.text.isNotEmpty) {
        await auth.updatePassword(_passwordController.text);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }
}
