import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hometouch/Common%20Pages/chat_hisotry_page.dart';
import 'package:hometouch/Common%20Pages/setting_page.dart';
import 'package:hometouch/Driver%20View/driver_dashboard_page.dart';
import 'package:hometouch/Driver%20View/driver_orders_page.dart';
import 'package:hometouch/Driver%20View/driver_profile_page.dart';
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
  bool isHelpExpanded = false;
  int? selectedSubItemIndex;
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
      final docSnapshot = await FirebaseFirestore.instance
          .collection('vendor')
          .doc(userId)
          .get();

      setState(() {
        userPhotoUrl = docSnapshot['Logo'] ?? '';
      });
    }
  }

  void showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 25, horizontal: 20),
          title: Text(
            'Sign Out?',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFBF0000),
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10),
              Container(
                alignment: Alignment.center,
                child: Text(
                  'Are you sure you want to sign out?',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Color(0xFFBF0000)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        await prefs.setBool('isLoggedIn', false);

                        if (mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const RoleSelectionPage()),
                            (route) => false,
                          );
                        }
                      },
                      child: Text(
                        'Yes',
                        style: TextStyle(
                          color: Color(0xFFBF0000),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFBF0000),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'No',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      width: screenWidth * 0.7,
      child: Drawer(
        child: Stack(
          children: [
            Container(
              color: Colors.white,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    height: screenHeight * 0.181,
                    decoration: const BoxDecoration(
                      color: Color(0xFFBF0000),
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: screenHeight * 0.05,
                        right: screenWidth * 0.03,
                        left: screenWidth * 0.05,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.menu, color: Colors.white),
                          ),
                          SizedBox(width: screenWidth * 0.07),
                          Text(
                            'HomeTouch',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: screenWidth * 0.05,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: screenHeight * 0.06),
                    child: Column(
                      children: [
                        _buildDrawerItem(
                          context,
                          index: 0,
                          icon: Icons.dashboard,
                          label: 'Dashboard',
                          screenWidth: screenWidth,
                          screenHeight: screenHeight,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => DriverDashboard()),
                            );
                          },
                        ),
                        _buildDrawerItem(
                          context,
                          index: 1,
                          icon: Icons.assignment,
                          label: 'Orders',
                          screenWidth: screenWidth,
                          screenHeight: screenHeight,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => DriverOrdersPage()),
                            );
                          },
                        ),
                        _buildDrawerItem(
                          context,
                          index: 2,
                          icon: Icons.person,
                          label: 'Profile',
                          screenWidth: screenWidth,
                          screenHeight: screenHeight,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => DriverProfilePage()),
                            );
                          },
                        ),
                        _buildDrawerItem(
                          context,
                          index: 5,
                          icon: Icons.message,
                          label: 'Messages',
                          screenWidth: screenWidth,
                          screenHeight: screenHeight,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      ChatListPage(currentUserId: userId)),
                            );
                          },
                        ),
                        _buildDrawerItem(
                          context,
                          index: 6,
                          icon: Icons.settings,
                          label: 'Settings',
                          screenWidth: screenWidth,
                          screenHeight: screenHeight,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SettingsPage()),
                            );
                          },
                        ),
                        _buildSignOutButton(context, screenWidth, screenHeight),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: screenHeight * 0.12,
              left: screenWidth * 0.23,
              child: Container(
                width: screenWidth * 0.25,
                height: screenWidth * 0.25,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: CircleAvatar(
                  radius: screenWidth * 0.125,
                  backgroundImage: userPhotoUrl != null &&
                          userPhotoUrl!.isNotEmpty
                      ? NetworkImage(userPhotoUrl!)
                      : const NetworkImage('https://i.imgur.com/OtAn7hT.jpeg'),
                ),
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
    void Function()? onTap,
    required double screenWidth,
    required double screenHeight,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
      child: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          children: [
            const Divider(color: Colors.grey, height: 4),
            ListTile(
              leading: Icon(icon, color: const Color(0xFFBF0000)),
              title: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: widget.selectedIndex == index
                      ? const Color(0xFFBF0000)
                      : Colors.black,
                  fontSize: screenWidth * 0.042,
                ),
              ),
              selected: widget.selectedIndex == index,
              selectedTileColor: const Color(0xFFBF0000),
              onTap: () {
                if (onTap != null) {
                  onTap();
                  widget.onItemTapped(index);
                } else {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
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
          side: BorderSide(color: Color(0xFFBF0000)),
          foregroundColor: Color(0xFFBF0000),
          padding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.015, horizontal: screenWidth * 0.07),
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenHeight * 0.02),
          ),
        ),
        onPressed: () {
          showSignOutDialog(context);
        },
        child: Text(
          'Sign Out',
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
