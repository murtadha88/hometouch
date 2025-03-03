import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hometouch/Customer%20View/about_us_page.dart';
import 'package:hometouch/Customer%20View/account_page.dart';
import 'package:hometouch/Customer%20View/faq_page.dart';
import 'package:hometouch/Customer%20View/favorite_page.dart';
import 'package:hometouch/Customer%20View/notification_page.dart';
import 'package:hometouch/Common%20Pages/setting_page.dart';

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
        userPhotoUrl = docSnapshot['Photo'];
        userPhotoUrl == "" ? userPhotoUrl = null : userPhotoUrl = userPhotoUrl;
      });
    }
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
                    decoration: BoxDecoration(
                      color: const Color(0xFFBF0000),
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
                            onTap: () {
                              Navigator.pop(context);
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
                    padding: EdgeInsets.only(top: screenHeight * 0.1),
                    child: Column(
                      children: [
                        _buildDrawerItem(
                          context,
                          index: 0,
                          icon: Icons.person,
                          label: 'Account',
                          screenWidth: screenWidth,
                          screenHeight: screenHeight,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AccountPage()),
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
                                  builder: (context) => FavoritesPage()),
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
                                  builder: (context) => NotificationPage()),
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
                                  builder: (context) => SettingsPage()),
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
                                  builder: (context) => AboutUs()),
                            );
                          },
                        ),
                        _buildDrawerItem(
                          context,
                          index: 5,
                          icon: Icons.help,
                          label: 'Help',
                          isExpandable: true,
                          isExpanded: isHelpExpanded,
                          onTap: () {
                            setState(() {
                              isHelpExpanded = !isHelpExpanded;
                              if (selectedSubItemIndex == null) {
                                widget.onItemTapped(5);
                              }
                            });
                          },
                          screenWidth: screenWidth,
                          screenHeight: screenHeight,
                          subItems: [
                            _buildSubItem(
                              context,
                              index: 6,
                              icon: Icons.question_answer,
                              label: 'FAQs',
                              onTap: () {
                                setState(() {
                                  selectedSubItemIndex = 6;
                                });
                                widget.onItemTapped(6);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => FAQ()),
                                );
                              },
                              screenWidth: screenWidth,
                              screenHeight: screenHeight,
                            ),
                            _buildSubItem(
                              context,
                              index: 7,
                              icon: Icons.chat,
                              label: 'Chat Bot',
                              onTap: () {
                                setState(() {
                                  selectedSubItemIndex = 7;
                                });
                                widget.onItemTapped(7);
                                Navigator.pop(context);
                              },
                              screenWidth: screenWidth,
                              screenHeight: screenHeight,
                            ),
                          ],
                        ),
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
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: screenWidth * 0.125,
                  backgroundImage: userPhotoUrl != null
                      ? NetworkImage(userPhotoUrl!)
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
    bool isExpandable = false,
    bool isExpanded = false,
    void Function()? onTap,
    List<Widget>? subItems,
    required double screenWidth,
    required double screenHeight,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: screenWidth * 0.06,
        right: screenWidth * 0.06,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
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
                      ? const Color(0xFFBF0000)
                      : Colors.black,
                  fontSize: screenWidth * 0.045,
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
    required double screenWidth,
    required double screenHeight,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: screenWidth * 0.08,
        right: screenWidth * 0.04,
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFBF0000)),
        title: Text(
          label,
          style: TextStyle(fontSize: screenWidth * 0.04),
        ),
        selected: selectedSubItemIndex == index,
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
    );
  }
}
