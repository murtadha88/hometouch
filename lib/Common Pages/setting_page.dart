import 'package:flutter/material.dart';
import '../Customer View/pravicy_policy_page.dart';
import '../Customer View/term_of_services_page.dart';
import '../Customer View/about_us_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isPushNotificationEnabled = false;
  bool isLocationEnabled = true;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(screenHeight * 0.09),
        child: AppBar(
          leading: Padding(
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
                    top: screenHeight * 0.001, left: screenWidth * 0.02),
                child: Icon(Icons.arrow_back_ios,
                    color: Colors.white, size: screenHeight * 0.025),
              ),
            ),
          ),
          title: Padding(
            padding: EdgeInsets.only(top: screenHeight * 0.02),
            child: Text(
              'Setting',
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
      body: Padding(
        padding: EdgeInsets.only(top: screenHeight * 0.03),
        child: ListView(
          children: [
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Text(
                'GENERAL',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: screenWidth * 0.05,
                ),
              ),
            ),
            ListTile(
              title: Text('Push Notification',
                  style: TextStyle(fontSize: screenWidth * 0.045)),
              trailing: Switch(
                value: isPushNotificationEnabled,
                activeColor: Colors.white,
                activeTrackColor: Color(0xFFBF0000),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Color(0xFFDFE0F3),
                onChanged: (value) {
                  setState(() {
                    isPushNotificationEnabled = value;
                  });
                },
              ),
            ),
            ListTile(
              title: Text('Location',
                  style: TextStyle(fontSize: screenWidth * 0.045)),
              trailing: Switch(
                value: isLocationEnabled,
                activeColor: Colors.white,
                activeTrackColor: Color(0xFFBF0000),
                onChanged: (value) {
                  setState(() {
                    isLocationEnabled = value;
                  });
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Text(
                'OTHER',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: screenWidth * 0.05,
                ),
              ),
            ),
            ListTile(
              title: Text('About Us',
                  style: TextStyle(fontSize: screenWidth * 0.045)),
              trailing: Icon(Icons.arrow_forward_ios, size: screenWidth * 0.04),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AboutUs()),
                );
              },
            ),
            ListTile(
              title: Text('Privacy Policy',
                  style: TextStyle(fontSize: screenWidth * 0.045)),
              trailing: Icon(Icons.arrow_forward_ios, size: screenWidth * 0.04),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PrivacyPolicy()),
                );
              },
            ),
            ListTile(
              title: Text('Terms of Service',
                  style: TextStyle(fontSize: screenWidth * 0.045)),
              trailing: Icon(Icons.arrow_forward_ios, size: screenWidth * 0.04),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TermsOfServicePage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
