import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkErrorPage extends StatefulWidget {
  final VoidCallback onConnectionRestored;

  const NetworkErrorPage({super.key, required this.onConnectionRestored});

  @override
  State<NetworkErrorPage> createState() => _NetworkErrorPageState();
}

class _NetworkErrorPageState extends State<NetworkErrorPage> {
  bool _isRetrying = false;

  Future<void> _retryConnection() async {
    setState(() {
      _isRetrying = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    var connectivityResult = await Connectivity().checkConnectivity();

    setState(() {
      _isRetrying = false;
    });

    if (connectivityResult != ConnectivityResult.none) {
      Navigator.of(context).pop(true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Still no internet connection. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _isRetrying
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFBF0000)),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Just a moment...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFBF0000),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/lost of connection.png',
                    width: 200,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Lost Connection',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFBF0000),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Whoops... no internet connection found.\nCheck your connection.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isRetrying ? null : _retryConnection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFBF0000),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 10),
                    ),
                    child: _isRetrying
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            'Retry',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
