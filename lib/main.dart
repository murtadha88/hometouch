import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hometouch/firebase_options.dart';
import 'Common Pages/progress_screen_page.dart';
import 'network_manager.dart'; // Import NetworkManager

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>(); // ✅ Global NavigatorKey

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // ✅ Assign navigator key
      home: const ProgressScreen(),
      builder: (context, child) {
        NetworkManager().startListening(); // ✅ Start monitoring globally
        return child!;
      },
    );
  }
}
