import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: "Poppins"),
    home: TermsOfServicePage(),
  ));
}

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(screenHeight * 0.1),
        child: AppBar(
          leading: Padding(
            padding: EdgeInsets.only(
                top: screenHeight * 0.03,
                left: screenWidth * 0.02,
                right: screenWidth * 0.02),
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
              'Terms Of Services',
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
            preferredSize: Size.fromHeight(screenHeight * 0.001),
            child: Divider(
              thickness: screenHeight * 0.001,
              color: Colors.grey[300],
              height: screenHeight * 0.002,
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: screenHeight * 0.02),
                child: Text(
                  'Acceptance of Terms',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                'By using HomeTouch, you agree to comply with these Terms of Service. If you disagree, do not use the app. We may update these Terms at any time, and changes are effective immediately upon posting in the app.',
                textAlign: TextAlign.justify,
                style: TextStyle(fontSize: screenWidth * 0.04),
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                'User Account',
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                'To access HomeTouch features, you may need to create an account. You are responsible for keeping your account information secure and for all activities under your account. Notify us immediately of any unauthorized use of your account.',
                textAlign: TextAlign.justify,
                style: TextStyle(fontSize: screenWidth * 0.04),
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                'Ordering and Payment',
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                'When placing an order, you agree to pay the specified amount, including taxes, delivery fees, and charges. Payment is processed securely through the app. HomeTouch is not responsible for payment failures or errors.',
                textAlign: TextAlign.justify,
                style: TextStyle(fontSize: screenWidth * 0.04),
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                'Delivery and Pickup',
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                'You can choose between delivery or pickup for your orders. HomeTouch works with third-party delivery services, and we are not responsible for delays, damages, or issues with the delivery process. Ensure that your delivery information is correct to avoid delays.',
                textAlign: TextAlign.justify,
                style: TextStyle(fontSize: screenWidth * 0.04),
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                'Limitation of Liability',
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                'HomeTouch is not liable for any damages, issues with food, delivery problems, or health-related concerns arising from the use of the app. You use the app at your own risk and are responsible for ensuring that your orders meet your needs.',
                textAlign: TextAlign.justify,
                style: TextStyle(fontSize: screenWidth * 0.04),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
