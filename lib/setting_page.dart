import 'package:flutter/material.dart';
import 'pravicy_policy_page.dart';
import 'term_of_services_page.dart';

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
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: AppBar(
          leading: Padding(
            padding: const EdgeInsets.only(top: 20.0, left: 8.0, right: 8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFBF0000),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.only(
                    top: 8.0, left: 12.0, right: 4.0, bottom: 8.0),
                child: Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Text(
              'Setting',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 20,
              ),
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(
              thickness: 1,
              color: Colors.grey[300],
              height: 1,
              indent: 0,
              endIndent: 0,
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'GENERAL',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ListTile(
              title: Text('Push Notification'),
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
              title: Text('Location'),
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
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'OTHER',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ListTile(
              title: Text('About Us'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PrivacyPolicy()),
                );
              },
            ),
            ListTile(
              title: Text('Privacy Policy'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PrivacyPolicy()),
                );
              },
            ),
            ListTile(
              title: Text('Terms of Service'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
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

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SettingsPage(),
  ));
}
