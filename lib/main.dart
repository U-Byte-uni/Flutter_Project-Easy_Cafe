import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'controllers/auth_controller.dart';
import 'controllers/cafe_controller.dart';
import 'views/main_navigation_wrapper.dart';
import 'views/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => CafeController()),
      ],
      child: const EasyCafeApp(),
    ),
  );
}

class EasyCafeApp extends StatelessWidget {
  const EasyCafeApp({super.key});

  @override
  Widget build(BuildContext context) {
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



         