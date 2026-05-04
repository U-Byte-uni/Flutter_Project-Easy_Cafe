import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import 'settings_screen.dart';
import 'order_history_screen.dart';
import 'favorites_screen.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final profile = auth.profile;
    final user = auth.user;
    final displayName = (profile?['full_name']?.toString().trim().isNotEmpty == true)
      ? profile!['full_name'].toString().trim()
      : (user?.userMetadata?['full_name']?.toString().trim().isNotEmpty == true)
        ? user!.userMetadata!['full_name'].toString().trim()
        : 'User';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: AppTheme.primaryColor,
              backgroundImage: (profile?['avatar_url'] != null && profile?['avatar_url'].toString().isNotEmpty == true) 
                ? NetworkImage(profile!['avatar_url'].toString()) 
                : null,
              child: (profile?['avatar_url'] == null || profile?['avatar_url'].toString().isEmpty == true) 
                ? const Icon(Icons.person, size: 60, color: Colors.black)
                : null,
            ),
            const SizedBox(height: 16),
            Text(
              displayName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: AppTheme.headingFontFamily,
              ),
            ),
            const SizedBox(height: 32),
            _buildProfileItem(Icons.shopping_bag_outlined, 'My Orders', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
            }),
            _buildProfileItem(Icons.favorite_border, 'Favorites', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
            }),
            _buildProfileItem(Icons.settings_outlined, 'Settings', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            }),
            _buildProfileItem(Icons.help_outline, 'Help Center', () {}),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
                onPressed: () => auth.signOut(),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Logout', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
    );
  }
}
