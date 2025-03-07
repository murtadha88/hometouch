import 'package:flutter/material.dart';

class VendorDashboard extends StatelessWidget {
  const VendorDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vendor Dashboard"),
        backgroundColor: const Color(0xFFBF0000),
      ),
      body: Center(
        child: Text(
          "Welcome to the Vendor Dashboard!",
        ),
      ),
    );
  }
}
