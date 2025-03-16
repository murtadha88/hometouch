import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hometouch/firebase_options.dart';
import 'Common Pages/progress_screen_page.dart';
import 'network_manager.dart';

const String braintreeTokenizationKey = "sandbox_q7krsq7f_6nwm8jysmwxnwx4z";

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
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: const ProgressScreen(),
      builder: (context, child) {
        NetworkManager().startListening();
        return child!;
      },
    );
  }
}
