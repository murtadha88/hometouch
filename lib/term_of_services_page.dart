import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: "Poppins"),
    home: TermsOfServicePage(),
  ));
}

class TermsOfServicePage extends StatelessWidget {
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
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              'Terms Of Services',
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Text(
                  'Acceptance of Terms',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                'By using HomeTouch, you agree to comply with these Terms of Service. If you disagree, do not use the app. We may update these Terms at any time, and changes are effective immediately upon posting in the app.',
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 16.0),
              Text(
                'User Account',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                'To access HomeTouch features, you may need to create an account. You are responsible for keeping your account information secure and for all activities under your account. Notify us immediately of any unauthorized use of your account.',
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 16.0),
              Text(
                'Ordering and Payment',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                'When placing an order, you agree to pay the specified amount, including taxes, delivery fees, and charges. Payment is processed securely through the app. HomeTouch is not responsible for payment failures or errors.',
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 16.0),
              Text(
                'Delivery and Pickup',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                'You can choose between delivery or pickup for your orders. HomeTouch works with third-party delivery services, and we are not responsible for delays, damages, or issues with the delivery process. Ensure that your delivery information is correct to avoid delays.',
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 16.0),
              Text(
                'Limitation of Liability',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                'HomeTouch is not liable for any damages, issues with food, delivery problems, or health-related concerns arising from the use of the app. You use the app at your own risk and are responsible for ensuring that your orders meet your needs.',
                textAlign: TextAlign.justify,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
