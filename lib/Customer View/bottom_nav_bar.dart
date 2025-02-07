import 'package:flutter/material.dart';
import 'home_page.dart';
import 'favorite_page.dart';
import 'cart_page2.dart';
import 'account_page.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;

  const BottomNavBar({super.key, required this.selectedIndex});

  void _onItemTapped(BuildContext context, int index) {
    if (selectedIndex == index) return; // Prevent unnecessary navigation

    Widget nextPage;
    switch (index) {
      case 0:
        nextPage = const HomeTouchScreen(isFromNavBar: true);
        break;
      case 1:
        nextPage = const FavoritesPage(isFromNavBar: true);
        break;
      case 2:
        nextPage = const CartPage2(isFromNavBar: true);
        break;
      case 3:
        nextPage = const AccountPage(isFromNavBar: true);
        break;
      case 4:
        nextPage = const AccountPage(isFromNavBar: true);
        break;
      default:
        nextPage = const HomeTouchScreen(isFromNavBar: true);
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(25),
        topRight: Radius.circular(25),
      ),
      child: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 5,
        child: SizedBox(
          height: 60, // ✅ Adjust height
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, Icons.home, "Home", 0),
              _buildNavItem(context, Icons.favorite_border, "Favorite", 1),
              const SizedBox(width: 40), // Space for FloatingActionButton
              _buildNavItem(context, Icons.list_alt, "Orders", 3),
              _buildNavItem(context, Icons.account_circle, "Account", 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, IconData icon, String label, int index) {
    bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(context, index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isSelected ? 32 : 22, // Enlarges when selected
            color: isSelected ? const Color(0xFFBF0000) : Colors.black45,
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isSelected ? 1.0 : 0.0, // Show label only when selected
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
