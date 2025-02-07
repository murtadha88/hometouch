import 'package:flutter/material.dart';
import 'package:hometouch/Customer%20View/bottom_nav_bar.dart';

class CartPage2 extends StatefulWidget {
  final bool isFromNavBar;

  const CartPage2({super.key, this.isFromNavBar = false});

  @override
  State<CartPage2> createState() => _CartPage2State();
}

class _CartPage2State extends State<CartPage2> {
  int _selectedIndex = 2; // ✅ Default to Cart

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),

      body: const Center(child: Text('Your Cart is Empty')),

      // ✅ Move bottomNavigationBar outside body
      bottomNavigationBar: BottomNavBar(selectedIndex: 2),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CartPage2()),
              );
            },
            backgroundColor: const Color(0xFFBF0000),
            shape: const CircleBorder(),
            elevation: 5,
            child:
                const Icon(Icons.shopping_cart, color: Colors.white, size: 30),
          ),

          // ✅ Show "Cart" label ONLY when cart is selected
          if (_selectedIndex == 2) ...[
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: 1.0, // 🔽 Only show label when selected
              child: Text(
                "Cart",
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFBF0000),
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
