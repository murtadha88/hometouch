import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hometouch/Common%20Pages/login_page.dart';
import 'package:hometouch/Customer%20View/bottom_nav_bar.dart';
import 'package:hometouch/Customer%20View/cart_page2.dart';
import 'package:hometouch/Customer%20View/favorite_page.dart';
import 'package:hometouch/Customer%20View/profile_page.dart';
import 'package:hometouch/Customer%20View/setting_page.dart';
import 'package:hometouch/Customer%20View/subscription_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AccountPage extends StatefulWidget {
  final bool isFromNavBar;

  const AccountPage({super.key, this.isFromNavBar = false});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  int trackNavBarIcons = 4;
  String? userPhotoUrl;
  String userName = 'Loading...';
  String userEmail = 'Loading...';
  int loyaltyPoints = 0;
  bool isSubscribed = false;
  int _selectedIndex = 4;

  @override
  void initState() {
    super.initState();
    _getUserInfo();
    _checkSubscriptionStatus();
  }

  Future<void> _getUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('Customer')
          .doc(user.uid)
          .get();

      setState(() {
        userName = docSnapshot['Name'] ?? 'Unknown';
        userEmail = docSnapshot['Email'] ?? 'Not Available';
        loyaltyPoints = docSnapshot['Loyalty_Points'] ?? 0;
        userPhotoUrl = docSnapshot['Photo'];
        userPhotoUrl == "" ? userPhotoUrl = null : userPhotoUrl = userPhotoUrl;
      });
    }
  }

  Future<void> _checkSubscriptionStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userRef = FirebaseFirestore.instance
          .collection('Customer')
          .doc(user.uid); // Reference to the current user's document

      final subscriptionSnapshot = await FirebaseFirestore.instance
          .collection('subscription')
          .where('Customer_ID',
              isEqualTo:
                  userRef) // Check if the reference matches the current user's reference
          .get();

      setState(() {
        isSubscribed = subscriptionSnapshot
            .docs.isNotEmpty; // Check if there's a subscription for this user
      });
    }
  }

  Future<void> _uploadPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File file = File(pickedFile.path);

      // Check if image size exceeds the 1MB limit
      int fileSize = await file.length();
      if (fileSize > 1048576) {
        // 1MB in bytes
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Image is too large. Please select a smaller image.',
              style: TextStyle(
                  color: Colors
                      .white), // Optional: Change text color to white for contrast
            ),
            backgroundColor: Colors.red, // Set background color to red
          ),
        );

        return;
      }

      // Convert image to base64 string
      List<int> imageBytes = await file.readAsBytes();
      String base64String = base64Encode(imageBytes);

      try {
        // Update Firestore with the base64 string
        await FirebaseFirestore.instance
            .collection('Customer')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({'Photo': base64String});

        setState(() {
          userPhotoUrl =
              base64String; // Update the state with the new base64 string
        });
      } catch (e) {
        print('Error uploading photo: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () async {
        return !widget.isFromNavBar; // 🔴 Prevent back if from NavBar
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(screenHeight * 0.1),
          child: AppBar(
            leading: widget.isFromNavBar
                ? const SizedBox()
                : Padding(
                    padding: EdgeInsets.only(
                      top: screenHeight * 0.03,
                      left: screenWidth * 0.02,
                      right: screenWidth * 0.02,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFBF0000),
                        ),
                        alignment: Alignment.center,
                        padding: EdgeInsets.all(screenHeight * 0.01),
                        child: Padding(
                          padding: EdgeInsets.only(left: screenWidth * 0.02),
                          child: Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: screenWidth * 0.055,
                          ),
                        ),
                      ),
                    ),
                  ),
            title: Padding(
              padding: EdgeInsets.only(top: screenHeight * 0.02),
              child: Text(
                'Account',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: screenWidth * 0.06,
                ),
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(screenHeight * 0.002),
              child: Divider(
                thickness: screenHeight * 0.001,
                color: Colors.grey[300],
                height: screenHeight * 0.002,
              ),
            ),
          ),
        ),
        backgroundColor: Colors.white,
        body: ListView(
          children: [
            _buildUserInfo(screenWidth, screenHeight),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.07),
              child: Divider(
                color: Color(0xFFBF0000),
                thickness: 2.0,
                height: 20.0,
              ),
            ),
            _buildMenuItem(
              'Profile',
              Icons.person,
              screenWidth,
              screenHeight,
              onTap: () async {
                final updatedUserInfo = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );

                // If data is returned from ProfilePage
                if (updatedUserInfo != null) {
                  setState(() {
                    userName = updatedUserInfo['name'];
                    userEmail = updatedUserInfo['email'];
                  });
                }
              },
            ),
            _buildMenuItem(
              'Subscription',
              FontAwesomeIcons.crown,
              screenWidth,
              screenHeight,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true, // Allow it to expand as needed
                  backgroundColor: Colors.transparent, // Transparent background
                  builder: (BuildContext context) {
                    return SubscriptionDialog(
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    );
                  },
                );
              },
            ),
            _buildMenuItem(
              'Overview',
              Icons.dashboard,
              screenWidth,
              screenHeight,
              onTap: isSubscribed
                  ? () {
                      // Navigate to Overview Page if subscribed
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                SettingsPage()), // Replace with actual overview page
                      );
                    }
                  : null,
            ),
            if (!isSubscribed)
              Padding(
                padding: EdgeInsets.only(left: screenWidth * 0.22),
                child: Text(
                  'Requires subscription',
                  style: TextStyle(
                    color: Color(0xFFBF0000),
                    fontSize: screenWidth * 0.033,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            _buildLoyaltyPoints(screenWidth, screenHeight),
            _buildMenuItem(
              'Rewards',
              FontAwesomeIcons.gift,
              screenWidth,
              screenHeight,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          SettingsPage()), // Navigate to SettingsPage
                );
              },
            ),
            _buildMenuItem(
              'Favorites',
              Icons.favorite,
              screenWidth,
              screenHeight,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          FavoritesPage()), // Navigate to SettingsPage
                );
              },
            ),
            _buildMenuItem(
              'Chat History',
              Icons.chat,
              screenWidth,
              screenHeight,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          SettingsPage()), // Navigate to SettingsPage
                );
              },
            ),
            _buildMenuItem(
              'Settings',
              Icons.settings,
              screenWidth,
              screenHeight,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          SettingsPage()), // Navigate to SettingsPage
                );
              },
            ),
            _buildSignOutButton(context, screenWidth, screenHeight),
          ],
        ),
        bottomNavigationBar: BottomNavBar(selectedIndex: 4),
        floatingActionButton: Container(
          height: 58, // Bigger size to overlap the bottom bar
          width: 58,
          child: FloatingActionButton(
            onPressed: () {
              if (_selectedIndex != 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const CartPage2()),
                );
              }
            },
            backgroundColor: const Color(0xFFBF0000),
            shape: const CircleBorder(),
            elevation: 5,
            child:
                const Icon(Icons.shopping_cart, color: Colors.white, size: 30),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget _buildUserInfo(double screenWidth, double screenHeight) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: screenWidth * 0.2,
                backgroundColor: Colors.grey[300],
                backgroundImage: userPhotoUrl != null
                    ? MemoryImage(
                        base64Decode(userPhotoUrl!)) // Show base64 image
                    : NetworkImage(
                        'https://i.imgur.com/OtAn7hT.jpeg',
                      ),
              ),
              Positioned(
                bottom: screenHeight * 0.01,
                right: screenWidth * 0.02,
                child: GestureDetector(
                  onTap: _uploadPhoto, // Allow the user to upload a photo
                  child: CircleAvatar(
                    radius: screenWidth * 0.06,
                    backgroundColor: Colors.grey[100],
                    child: Icon(
                      Icons.edit,
                      size: screenWidth * 0.05,
                      color: Color(0xFFBF0000),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            userName,
            style: TextStyle(
                fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(userEmail),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      String title, IconData icon, double screenWidth, double screenHeight,
      {void Function()? onTap}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: ListTile(
        leading: title == "Overview"
            ? isSubscribed
                ? Icon(icon, color: Color(0xFFBF0000))
                : Icon(icon, color: Color.fromARGB(255, 134, 134, 134))
            : Icon(icon, color: Color(0xFFBF0000)),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: title == "Overview"
            ? isSubscribed
                ? Icon(Icons.chevron_right, color: Color(0xFFBF0000))
                : Icon(Icons.chevron_right,
                    color: Color.fromARGB(255, 134, 134, 134))
            : Icon(Icons.chevron_right, color: Color(0xFFBF0000)),
        onTap: () {
          if (onTap != null) {
            onTap();
          } else {
            null;
          }
        },
      ),
    );
  }

  Widget _buildLoyaltyPoints(double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: ListTile(
        leading: Icon(Icons.loyalty, color: Color(0xFFBF0000)),
        title: Text(
          'Loyalty Points',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: Text(
          '$loyaltyPoints',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFBF0000),
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutButton(
      BuildContext context, double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.only(
          top: screenHeight * 0.02,
          bottom: screenHeight * 0.02,
          left: screenWidth * 0.2,
          right: screenWidth * 0.2),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Color(0xFFBF0000)),
          foregroundColor: Color(0xFFBF0000),
          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
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
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                LoginPage(), // Redirect to login page
                          ),
                        );
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
                        // Handle "No" action here
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
}
