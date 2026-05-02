import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final auth = context.read<AuthController>();
    final messenger = ScaffoldMessenger.of(context);
    
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final name = _nameController.text.trim();

      if (_isSignUp) {
        if (name.isEmpty) {
          messenger.showSnackBar(const SnackBar(content: Text("Please enter your name")));
          return;
        }
        await auth.signUp(email, password, name);
      } else {
        await auth.signIn(email, password);
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              const Text(
                "Welcome to\nEasy Cafe",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                _isSignUp ? "Create an account to continue" : "Login to your account",
                style: const TextStyle(color: AppTheme.secondaryTextColor),
              ),
              const SizedBox(height: 50),
              if (_isSignUp) ...[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: "Full Name",
                    prefixIcon: Icon(Icons.person, color: AppTheme.secondaryTextColor),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: "Email Address",
                  prefixIcon: Icon(Icons.email, color: AppTheme.secondaryTextColor),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: "Password",
                  prefixIcon: Icon(Icons.lock, color: AppTheme.secondaryTextColor),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: Consumer<AuthController>(
                  builder: (context, auth, child) {
                    return ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleAuth,
                      child: auth.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(_isSignUp ? "Sign Up" : "Login"),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(
                    _isSignUp
                        ? "Already have an account? Login"
                        : "Don't have an account? Sign Up",
                    style: const TextStyle(color: AppTheme.primaryColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
