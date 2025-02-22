import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hometouch/Common%20Pages/network_error_page.dart';
import 'main.dart';

class NetworkManager {
  static final NetworkManager _instance = NetworkManager._internal();
  factory NetworkManager() => _instance;
  NetworkManager._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;
  bool _isErrorPageShown = false;

  void startListening() {
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.none) {
        _showNetworkErrorPage();
      } else {
        _removeNetworkErrorPage();
      }
    });
  }

  void stopListening() {
    _subscription?.cancel();
  }

  void _showNetworkErrorPage() {
    if (_isErrorPageShown) return;
    _isErrorPageShown = true;

    MyApp.navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => NetworkErrorPage(
          onConnectionRestored: _removeNetworkErrorPage,
        ),
      ),
    );
  }

  void _removeNetworkErrorPage() {
    if (!_isErrorPageShown) return;
    _isErrorPageShown = false;

    MyApp.navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }
}
