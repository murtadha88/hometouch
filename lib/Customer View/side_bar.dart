import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hometouch/Customer%20View/about_us_page.dart';
import 'package:hometouch/Customer%20View/account_page.dart';
import 'package:hometouch/Customer%20View/faq_page.dart';
import 'package:hometouch/Customer%20View/favorite_page.dart';
import 'package:hometouch/Customer%20View/notification_page.dart';
import 'package:hometouch/Customer%20View/setting_page.dart';

class DrawerScreen extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const DrawerScreen({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  _DrawerScreenState createState() => _DrawerScreenState();
}

class _DrawerScreenState extends State<DrawerScreen> {
  bool isHelpExpanded = false; // Track if "Help" menu is expanded
  int? selectedSubItemIndex; // Track selected sub-item index
  String? userPhotoUrl;

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  Future<void> _getUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('Customer')
          .doc(user.uid)
          .get();

      setState(() {
        userPhotoUrl = docSnapshot['Photo'] ?? null;
        userPhotoUrl == "" ? userPhotoUrl = null : userPhotoUrl = userPhotoUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: screenWidth * 0.7,
      child: Drawer(
        child: Stack(
          children: [
            // Ensuring the background is white
            Container(
              color: Colors
                  .white, // This will ensure the whole drawer has a white background
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Drawer header with a container instead of DrawerHeader
                  Container(
                    height: screenHeight * 0.181, // Custom height for header
                    decoration: BoxDecoration(
                      color: const Color(
                          0xFFBF0000), // Background color for the header
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: screenHeight *
                            0.05, // Adjust bottom padding to reduce height
                        right: screenWidth * 0.03, // Adjust padding dynamically
                        left: screenWidth * 0.05,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context); // Close the drawer
                            },
                            child: Icon(
                              Icons.menu,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(
                            width: screenWidth * 0.07,
                          ),
                          Text(
                            'HomeTouch', // Title text
                            style: TextStyle(
                              color: Colors.white, // White color for the text
                              fontWeight: FontWeight.w800, // ExtraBold weight
                              fontSize:
                                  screenWidth * 0.05, // Adjusted font size
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // The main list of items below the header
                  Padding(
                    padding: EdgeInsets.only(top: screenHeight * 0.1),
                    child: Column(
                      children: [
                        _buildDrawerItem(
                          context,
                          index: 0,
                          icon: Icons.person,
                          label: 'Account',
                          screenWidth: screenWidth, // Pass screenWidth
                          screenHeight: screenHeight, // Pass screenHeight
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      AccountPage()), // Navigate to SettingsPage
                            );
                          },
                        ),
                        _buildDrawerItem(
                          context,
                          index: 1,
                          icon: Icons.favorite,
                          label: 'Favorite',
                          screenWidth: screenWidth,
                          screenHeight: screenHeight,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      FavoritesPage()), // Navigate to SettingsPage
                            );
                          },
                        ),
                        _buildDrawerItem(
                          context,
                          index: 2,
                          icon: Icons.notifications,
                          label: 'Notification',
                          screenWidth: screenWidth,
                          screenHeight: screenHeight,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      NotificationPage()), // Navigate to SettingsPage
                            );
                          },
                        ),
                        _buildDrawerItem(
                          context,
                          index: 3,
                          icon: Icons.settings,
                          label: 'Setting',
                          screenWidth: screenWidth,
                          screenHeight: screenHeight,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      SettingsPage()), // Navigate to SettingsPage
                            );
                          },
                        ),
                        _buildDrawerItem(
                          context,
                          index: 4,
                          icon: Icons.info,
                          label: 'About Us',
                          screenWidth: screenWidth,
                          screenHeight: screenHeight,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      AboutUs()), // Navigate to SettingsPage
                            );
                          },
                        ),
                        // Help item with expandable content inside the same design
                        _buildDrawerItem(
                          context,
                          index: 5,
                          icon: Icons.help,
                          label: 'Help',
                          isExpandable: true, // Flag for expandable item
                          isExpanded: isHelpExpanded,
                          onTap: () {
                            setState(() {
                              isHelpExpanded =
                                  !isHelpExpanded; // Toggle expansion
                              if (selectedSubItemIndex == null) {
                                widget.onItemTapped(5); // Highlight Help item
                              }
                            });
                          },
                          screenWidth: screenWidth, // Pass screenWidth here
                          screenHeight: screenHeight, // Pass screenHeight here
                          subItems: [
                            _buildSubItem(
                              context,
                              index: 6,
                              icon: Icons.question_answer,
                              label: 'FAQs',
                              onTap: () {
                                setState(() {
                                  selectedSubItemIndex =
                                      6; // Mark FAQ as selected
                                });
                                widget.onItemTapped(6);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => FAQ()),
                                );
                              },
                              screenWidth: screenWidth, // Pass screenWidth
                              screenHeight: screenHeight, // Pass screenHeight
                            ),
                            _buildSubItem(
                              context,
                              index: 7,
                              icon: Icons.chat,
                              label: 'Chat Bot',
                              onTap: () {
                                setState(() {
                                  selectedSubItemIndex =
                                      7; // Mark Chat Bot as selected
                                });
                                widget.onItemTapped(
                                    7); // Close drawer and select sub-item
                                Navigator.pop(context); // Close the drawer
                              },
                              screenWidth: screenWidth, // Pass screenWidth
                              screenHeight: screenHeight, // Pass screenHeight
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Profile picture positioned over the header
            Positioned(
              top: screenHeight * 0.12, // Adjust dynamically
              left: screenWidth * 0.23, // Adjust dynamically
              child: Container(
                width:
                    screenWidth * 0.25, // Slightly smaller profile picture size
                height:
                    screenWidth * 0.25, // Slightly smaller profile picture size
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: screenWidth * 0.125, // Slightly smaller radius
                  backgroundImage: userPhotoUrl != null
                      ? MemoryImage(
                          base64Decode(userPhotoUrl!)) // Show base64 image
                      : NetworkImage(
                          'https://i.imgur.com/OtAn7hT.jpeg',
                        ),
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
    bool isExpandable = false, // Flag to indicate expandable
    bool isExpanded = false, // Flag for expanded state
    void Function()? onTap, // onTap for expanding
    List<Widget>? subItems, // List of sub-items if expandable
    required double screenWidth, // Pass screenWidth here
    required double screenHeight, // Pass screenHeight here
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: screenWidth * 0.06, // Reduced left padding
        right: screenWidth * 0.06,
      ), // Adjusted right padding
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // Ensure background is white
        ),
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
                      ? const Color(0xFFBF0000) // Red text when selected
                      : Colors.black, // Black text when not selected
                  fontSize: screenWidth * 0.045, // Slightly smaller font size
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
            if (isExpandable && isExpanded) ...[...subItems!],
          ],
        ),
      ),
    );
  }

  Widget _buildSubItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    void Function()? onTap,
    required double screenWidth, // Pass screenWidth here
    required double screenHeight, // Pass screenHeight here
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: screenWidth * 0.08, // Adjusted left padding for sub-items
        right: screenWidth * 0.04,
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFBF0000)),
        title: Text(
          label,
          style: TextStyle(
              fontSize: screenWidth * 0.04), // Slightly smaller font size
        ),
        selected: selectedSubItemIndex == index, // Highlight selected sub-item
        selectedTileColor:
            const Color(0xFFBF0000), // Red background when selected
        onTap: () {
          if (onTap != null) {
            onTap();
            widget.onItemTapped(index);
          } else {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
