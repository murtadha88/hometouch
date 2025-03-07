import 'package:flutter/material.dart';

class DriverDashboard extends StatelessWidget {
  const DriverDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver Dashboard"),
        backgroundColor: const Color(0xFFBF0000),
      ),
      body: Center(
        child: Text(
          "Welcome to the Driver Dashboard!",
        ),
      ),
    );
  }
}
