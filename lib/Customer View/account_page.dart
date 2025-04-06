import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hometouch/Common%20Pages/role_page.dart';
import 'package:hometouch/Customer%20View/bottom_nav_bar.dart';
import 'package:hometouch/Customer%20View/cart_page.dart';
import 'package:hometouch/Common%20Pages/chat_hisotry_page.dart';
import 'package:hometouch/Customer%20View/favorite_page.dart';
import 'package:hometouch/Customer%20View/profile_page.dart';
import 'package:hometouch/Common%20Pages/setting_page.dart';
import 'package:hometouch/Customer%20View/rewards_page.dart';
import 'package:hometouch/Customer%20View/subscription_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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
  String userId = "";
  int loyaltyPoints = 0;
  bool isSubscribed = false;
  final int _selectedIndex = 4;

  @override
  void initState() {
    super.initState();
    _getUserInfo();
    _checkSubscriptionStatus();
  }

  Future<void> _getUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
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
      final userRef =
          FirebaseFirestore.instance.collection('Customer').doc(user.uid);

      final subscriptionSnapshot = await FirebaseFirestore.instance
          .collection('subscription')
          .where('Customer_ID', isEqualTo: userRef)
          .get();

      setState(() {
        isSubscribed = subscriptionSnapshot.docs.isNotEmpty;
      });
    }
  }

  Future<void> _uploadPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    File file = File(pickedFile.path);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("https://api.imgur.com/3/upload"),
      );

      request.headers['Authorization'] = 'Client-ID ca25aec45d48f73';
      request.files.add(await http.MultipartFile.fromPath('image', file.path));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseData);

      if (jsonResponse['success'] == true) {
        String imageUrl = jsonResponse['data']['link'];

        await FirebaseFirestore.instance
            .collection('Customer')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({'Photo': imageUrl});

        setState(() {
          userPhotoUrl = imageUrl;
        });
      } else {
        throw Exception("Failed to upload image");
      }
    } catch (e) {
      print("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () async {
        return !widget.isFromNavBar;
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(screenHeight * 0.09),
          child: AppBar(
            leading: widget.isFromNavBar
                ? SizedBox()
                : Padding(
                    padding: EdgeInsets.only(
                        top: screenHeight * 0.025, left: screenWidth * 0.02),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFBF0000),
                        ),
                        alignment: Alignment.center,
                        padding: EdgeInsets.only(
                            top: screenHeight * 0.001,
                            left: screenWidth * 0.02),
                        child: Icon(Icons.arrow_back_ios,
                            color: Colors.white, size: screenHeight * 0.025),
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
                  fontSize: screenHeight * 0.027,
                ),
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(screenHeight * 0.002),
              child: Divider(
                  thickness: screenHeight * 0.001, color: Colors.grey[300]),
            ),
          ),
        ),
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  _buildUserInfo(screenWidth, screenHeight),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: screenWidth * 0.07),
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfilePage()),
                      ).then((_) {
                        _getUserInfo();
                      });
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
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (BuildContext context) {
                          return SubscriptionDialog(
                            screenWidth: screenWidth,
                            screenHeight: screenHeight,
                            isSubscribed: isSubscribed,
                          );
                        },
                      ).then((_) {
                        _checkSubscriptionStatus();
                      });
                    },
                  ),
                  _buildMenuItem(
                    'Overview',
                    Icons.dashboard,
                    screenWidth,
                    screenHeight,
                    onTap: isSubscribed
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SettingsPage()),
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
                        MaterialPageRoute(builder: (context) => RewardsPage()),
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
                            builder: (context) => FavoritesPage()),
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
                            builder: (context) => ChatListPage(
                                  currentUserId: userId,
                                )),
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
                        MaterialPageRoute(builder: (context) => SettingsPage()),
                      );
                    },
                  ),
                  _buildSignOutButton(context, screenWidth, screenHeight),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavBar(selectedIndex: 4),
        floatingActionButton: SizedBox(
          height: 58,
          width: 58,
          child: FloatingActionButton(
            onPressed: () {
              if (_selectedIndex != 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CartPage(isFromNavBar: true)),
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
                    ? NetworkImage(userPhotoUrl!)
                    : NetworkImage(
                        'https://i.imgur.com/OtAn7hT.jpeg',
                      ),
              ),
              Positioned(
                bottom: screenHeight * 0.01,
                right: screenWidth * 0.02,
                child: GestureDetector(
                  onTap: _uploadPhoto,
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
          bottom: screenHeight * 0.05,
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
}
