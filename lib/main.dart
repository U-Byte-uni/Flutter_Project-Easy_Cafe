import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'controllers/auth_controller.dart';
import 'controllers/cafe_controller.dart';
import 'controllers/cart_controller.dart';
import 'views/main_navigation_wrapper.dart';
import 'views/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  String? errorMessage;

  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");

    // Initialize Supabase
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
  } catch (e) {
    errorMessage = e.toString();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => CafeController()),
        ChangeNotifierProvider(create: (_) => CartController()),
      ],
      child: EasyCafeApp(error: errorMessage),
    ),
  );
}

class EasyCafeApp extends StatelessWidget {
  final String? error;
  const EasyCafeApp({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 80, color: AppTheme.primaryColor),
                  const SizedBox(height: 24),
                  const Text(
                    "Connection Error",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "We couldn't connect to our servers. Please check your internet connection and try again.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 30),
                  if (error != null)
                    Text(
                      "Error: $error",
                      style: const TextStyle(fontSize: 10, color: Colors.white24),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Easy Cafe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Consumer<AuthController>(
        builder: (context, auth, _) {
          if (auth.isAuthenticated) {
            return const MainNavigationWrapper();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}



         