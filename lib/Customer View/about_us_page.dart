import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUs extends StatelessWidget {
  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void showSignOutDialog(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          width: screenWidth,
          height: screenHeight * 0.2,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 234, 234, 234),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(screenWidth * 0.08),
              topRight: Radius.circular(screenWidth * 0.08),
            ),
            border: Border(
              top: BorderSide(
                  color: Color(0xFFBF0000), width: screenHeight * 0.005),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: screenHeight * 0.02),
              contactRow(
                  Icons.phone, '+973 3333 3333', screenWidth, screenHeight),
              contactRow(Icons.email, 'hometouch.bahrain@gmail.com',
                  screenWidth, screenHeight),
            ],
          ),
        );
      },
    );
  }

  Widget contactRow(
      IconData icon, String text, double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: screenHeight * 0.01, horizontal: screenWidth * 0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Color(0xFFBF0000), size: screenHeight * 0.025),
          SizedBox(width: screenWidth * 0.02),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: screenHeight * 0.023,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

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
              'About Us',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: screenHeight * 0.027,
              ),
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(screenHeight * 0.002),
            child: Divider(
                thickness: screenHeight * 0.001, color: Colors.grey[300]),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.only(
            left: screenWidth * 0.08,
            right: screenWidth * 0.08,
            bottom: screenHeight * 0.13),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                'https://i.imgur.com/N5YXynf.jpeg',
                height: screenHeight * 0.25,
                width: screenWidth * 0.8,
                fit: BoxFit.contain,
              ),
              SizedBox(height: screenHeight * 0.03),
              Text(
                'HomeTouch',
                style: TextStyle(
                  color: Color(0xFFBF0000),
                  fontSize: screenHeight * 0.035,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                'A dynamic platform that connects customers with homemade food startups and food trucks, offering a convenient way to explore and enjoy a variety of meals. Designed to support local entrepreneurs, HomeTouch provides real-time order tracking, multiple payment options, and direct communication through live chat.',
                textAlign: TextAlign.justify,
                style: TextStyle(fontSize: screenHeight * 0.018),
              ),
              SizedBox(height: screenHeight * 0.05),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  socialIcon('https://i.imgur.com/D8fux9Y.jpeg', screenHeight,
                      screenWidth, context),
                  SizedBox(width: screenWidth * 0.1),
                  socialIcon('https://i.imgur.com/qq75tvy.jpeg', screenHeight,
                      screenWidth, context),
                  SizedBox(width: screenWidth * 0.1),
                  socialIcon('https://i.imgur.com/7UCO342.jpeg', screenHeight,
                      screenWidth, context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget socialIcon(String url, double screenHeight, double screenWidth,
      BuildContext context) {
    return GestureDetector(
      onTap: () => {
        if (url == 'https://i.imgur.com/D8fux9Y.jpeg')
          showSignOutDialog(context)
        else if (url == 'https://i.imgur.com/qq75tvy.jpeg')
          _launchURL('https://www.instagram.com/hometouch.bhr')
        else if (url == 'https://i.imgur.com/7UCO342.jpeg')
          _launchURL('https://www.tiktok.com/@hometouch.bhr')
      },
      child: Image.network(
        url,
        height: screenHeight * 0.05,
        width: screenHeight * 0.05,
        fit: BoxFit.fill,
      ),
    );
  }
}
