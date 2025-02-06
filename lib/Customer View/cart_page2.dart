import 'package:flutter/material.dart';
import 'package:hometouch/Customer%20View/acoount_page.dart';
import 'package:hometouch/Customer%20View/favorite_page.dart';
import 'package:hometouch/Customer%20View/home_page.dart';

class CartPage2 extends StatefulWidget {
  const CartPage2({super.key});

  @override
  State<CartPage2> createState() => _CartPage2State();
}

class _CartPage2State extends State<CartPage2> {
  int _selectedIndex = 2; // ✅ Default to Cart

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return; // Prevent unnecessary rebuilds

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeTouchScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => FavoritesPage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => FavoritesPage()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AccountPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),

      body: const Center(child: Text('Your Cart is Empty')),

      // ✅ Move bottomNavigationBar outside body
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 2,
        color: Colors.white,
        child: SizedBox(
          height: 50, // ✅ Adjust height
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, "Home", 0),
              _buildNavItem(Icons.favorite_border, "Favorite", 1),
              const SizedBox(width: 40), // Space for FloatingActionButton
              _buildNavItem(Icons.list_alt, "Orders", 3),
              _buildNavItem(Icons.account_circle, "Account", 4),
            ],
          ),
        ),
      ),
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

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isSelected ? 32 : 22, // 🔼 Enlarges when selected
            color: isSelected ? const Color(0xFFBF0000) : Colors.black45,
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isSelected ? 1.0 : 0.0, // 🔽 Only show label when selected
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFFBF0000)),
            ),
          ),
        ],
      ),
    );
  }
}
