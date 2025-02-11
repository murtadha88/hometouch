import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hometouch/Customer%20View/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'welcome_page.dart';
import 'login_page.dart';
import 'network_error_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  double _progress = 0.0;
  String _statusText = "Starting...";
  Timer? _timer;
  late StreamSubscription<dynamic> _connectivitySubscription;
  bool _isNavigating = false;
  bool _hasConnection = true;
  bool _isOnNetworkErrorPage = false;

  @override
  void initState() {
    super.initState();
    _startProgress();

    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((dynamic result) {
      if (result is ConnectivityResult) {
        _handleConnectivityChange(result);
      } else if (result is List<ConnectivityResult>) {
        if (result.isNotEmpty) {
          _handleConnectivityChange(result.first);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void _startProgress() {
    _timer = Timer.periodic(const Duration(milliseconds: 300), (timer) async {
      setState(() {
        _progress += 0.06;

        if (_progress < 0.3) {
          _statusText = "Starting...";
        } else if (_progress < 0.6) {
          _statusText = "In Progress...";
        } else if (_progress < 1.0) {
          _statusText = "Almost Done...";
        } else {
          _statusText = "Completed!";
          _progress = 1.0;
          _isNavigating = false;
          _checkNetwork();
          _timer?.cancel();
        }
      });
    });
  }

  Future<void> _checkNetwork() async {
    if (_isNavigating) return;

    var connectivityResult = await Connectivity().checkConnectivity();
    _hasConnection = connectivityResult != ConnectivityResult.none;

    if (!_hasConnection) {
      _navigateToNetworkErrorPage();
    } else {
      await _checkFirstTime();
    }
  }

  Future<void> _checkFirstTime() async {
    if (_isNavigating) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('isFirstTime') ?? true;
    bool isLoggedIn =
        prefs.getBool('isLoggedIn') ?? false; // ✅ Track login status
    User? user = FirebaseAuth.instance.currentUser;

    setState(() {
      _isNavigating = true;
      _isOnNetworkErrorPage = false;
    });

    if (isFirstTime) {
      // ✅ First-time user → Go to Welcome Page
      await prefs.setBool('isFirstTime', false);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomePage()),
        );
      }
    } else if (!isLoggedIn || user == null) {
      // ✅ User NOT logged in → Go to Login Page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } else {
      // ✅ User already logged in → Go to Home Page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeTouchScreen()),
        );
      }
    }

    setState(() {
      _isNavigating = false;
    });
  }

  void _handleConnectivityChange(ConnectivityResult result) {
    bool hasConnectivity = result != ConnectivityResult.none;

    if (!hasConnectivity && !_isOnNetworkErrorPage) {
      _navigateToNetworkErrorPage();
    } else if (hasConnectivity && _isOnNetworkErrorPage) {
      setState(() {
        _isOnNetworkErrorPage = false;
      });
      _checkNetwork();
    }
  }

  void _navigateToNetworkErrorPage() async {
    if (_isNavigating || !mounted || _isOnNetworkErrorPage) return;

    setState(() {
      _isNavigating = true;
      _isOnNetworkErrorPage = true;
    });

    bool? isNetworkRestored = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NetworkErrorPage(
          onConnectionRestored: () {
            setState(() {
              _progress = 0.0;
              _statusText = "Starting...";
            });
            _startProgress();
            setState(() {
              _isNavigating = false;
              _isOnNetworkErrorPage = false;
            });
            _checkNetwork();
          },
        ),
      ),
    );

    if (isNetworkRestored == true) {
      setState(() {
        _progress = 0.0;
        _statusText = "Starting...";
      });
      _startProgress();
      _checkNetwork();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 40.0),
                  child: Image.asset(
                    "assets/logo.png",
                    width: 350,
                    height: 350,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.image_not_supported,
                        size: 100,
                        color: Colors.grey,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 12,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFBF0000)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '${(_progress * 100).toInt()}% $_statusText',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFBF0000)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
