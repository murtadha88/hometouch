import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hometouch/Common%20Pages/chat_hisotry_page.dart';
import 'package:hometouch/Common%20Pages/setting_page.dart';
import 'package:hometouch/Common%20Pages/review_page.dart';
import 'package:hometouch/Vendor%20View/discount_promotion_page.dart';
import 'package:hometouch/Vendor%20View/vendor_profile_page.dart';
import 'package:hometouch/Vendor%20View/menu_management_page.dart';
import 'package:hometouch/Vendor%20View/orders_management_page.dart';
import 'package:hometouch/Vendor%20View/poll_management_page.dart';
import 'package:hometouch/Vendor%20View/vendor_dashboard_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hometouch/Common%20Pages/role_page.dart';

class DrawerScreen extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const DrawerScreen({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  _DrawerScreenState createState() => _DrawerScreenState();
}

class _DrawerScreenState extends State<DrawerScreen> {
  String? userPhotoUrl;
  String userId = "";

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  Future<void> _getUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
      final doc = await FirebaseFirestore.instance
          .collection('vendor')
          .doc(userId)
          .get();
      setState(() {
        userPhotoUrl = doc['Logo'] ?? '';
      });
    }
  }

  void showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Sign Out?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFBF0000),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            const Text(
              'Are you sure you want to sign out?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFBF0000)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('isLoggedIn', false);
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RoleSelectionPage()),
                          (_) => false,
                        );
                      }
                    },
                    child: const Text(
                      'Yes',
                      style: TextStyle(
                          color: Color(0xFFBF0000),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBF0000),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'No',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return SizedBox(
      width: w * 0.7,
      child: Drawer(
        child: Column(
          children: [
            // Fixed header (never scrolls)
            SizedBox(
              height: h * 0.25,
              child: Stack(
                children: [
                  Container(
                    color: const Color(0xFFBF0000),
                    width: double.infinity,
                    height: h * 0.18,
                    padding: EdgeInsets.only(
                      bottom: h * 0.05,
                      left: w * 0.05,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.menu, color: Colors.white),
                        ),
                        SizedBox(width: w * 0.07),
                        const Text(
                          'HomeTouch',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: h * 0.12,
                    left: w * 0.23,
                    child: CircleAvatar(
                      radius: w * 0.125,
                      backgroundImage:
                          (userPhotoUrl != null && userPhotoUrl!.isNotEmpty)
                              ? NetworkImage(userPhotoUrl!)
                              : const NetworkImage(
                                  'https://i.imgur.com/OtAn7hT.jpeg'),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable menu items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    context,
                    index: 0,
                    icon: Icons.dashboard,
                    label: 'Dashboard',
                    screenWidth: w,
                    screenHeight: h,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const VendorDashboard()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    index: 1,
                    icon: Icons.assignment,
                    label: 'Orders Management',
                    screenWidth: w,
                    screenHeight: h,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const OrderManagementPage()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    index: 2,
                    icon: Icons.menu,
                    label: 'Menu Management',
                    screenWidth: w,
                    screenHeight: h,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => FoodMenuPage(vendorId: userId)),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    index: 6,
                    icon: Icons.person,
                    label: 'Profile',
                    screenWidth: w,
                    screenHeight: h,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const VendorProfilePage()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    index: 4,
                    icon: Icons.local_offer,
                    label: 'Promotions & Discounts',
                    screenWidth: w,
                    screenHeight: h,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PromotionDiscountPage()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    index: 5,
                    icon: Icons.message,
                    label: 'Messages',
                    screenWidth: w,
                    screenHeight: h,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                ChatListPage(currentUserId: userId)),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    index: 7,
                    icon: Icons.thumb_up,
                    label: 'Reviews and Rating',
                    screenWidth: w,
                    screenHeight: h,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ReviewPage(vendorId: userId, isVendor: true),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    index: 8,
                    icon: Icons.poll,
                    label: 'Poll Management',
                    screenWidth: w,
                    screenHeight: h,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PollPage()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    index: 6,
                    icon: Icons.settings,
                    label: 'Settings',
                    screenWidth: w,
                    screenHeight: h,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      );
                    },
                  ),
                  _buildSignOutButton(context, w, h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required double screenWidth,
    required double screenHeight,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
      child: Column(
        children: [
          const Divider(color: Colors.grey, height: 4),
          ListTile(
            leading: Icon(icon, color: const Color(0xFFBF0000)),
            title: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: screenWidth * 0.042,
                color: widget.selectedIndex == index
                    ? const Color(0xFFBF0000)
                    : Colors.black,
              ),
            ),
            selected: widget.selectedIndex == index,
            onTap: () {
              if (onTap != null) onTap();
              widget.onItemTapped(index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton(
      BuildContext context, double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.only(
        top: screenHeight * 0.02,
        bottom: screenHeight * 0.05,
        left: screenWidth * 0.17,
        right: screenWidth * 0.17,
      ),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFBF0000)),
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenHeight * 0.02),
          ),
        ),
        onPressed: () => showSignOutDialog(context),
        child: Text(
          'Sign Out',
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFBF0000),
          ),
        ),
      ),
    );
  }
}
