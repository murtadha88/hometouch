import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: PrivactPolicy(),
  ));
}

class PrivactPolicy extends StatelessWidget {
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
              'Privacy Policy',
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Text(
                  'Introduction',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                'This Privacy Policy outlines the types of information collected by HomeTouch, how it is used, and the measures we take to protect your privacy. By using our website or app, you consent to the collection, use, and disclosure of your information as described in this policy.',
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 16.0),
              Text(
                'Information We Collect',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                'When you use HomeTouch, we collect various types of information to enhance our services and provide a better user experience. This may include personally identifiable information such as your name, address, phone number, email address, and payment details, which are securely handled. We may also collect geolocation data to ensure accurate delivery services and usage information about your interactions with our app and website, such as browsing history and preferences. Sensitive personal information, including driver’s license or credit card numbers, may be collected where necessary for identification, security, or processing transactions.',
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 16.0),
              Text(
                'How We Use Your Information',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                'The information we collect is used to process orders, fulfill your requests, and improve our services. It helps us provide administrative support, detect and prevent fraud, and deliver personalized content and recommendations. We may use this data to communicate updates, promotions, and newsletters, provided you have given your consent. To enhance our services, we may share your information with participating merchants, third-party service providers, and legal authorities when required. Additionally, aggregated and anonymized data may be used for analytics, traffic analysis, and targeted advertisements to improve the functionality of our app and website.',
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 16.0),
              Text(
                'Cookies and Tracking Technologies',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                'HomeTouch also uses cookies and other tracking technologies to automatically collect usage data whenever you interact with our platform. This data includes details about your device, operating system, and browsing activity. Such information allows us to diagnose technical issues, secure our platform, and improve your overall experience. Although this data is non-personally identifiable, we may share it with analytics partners and service providers for operational purposes.',
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 16.0),
              Text(
                'Compliance and Legal Disclosures',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                'To comply with legal requirements or protect our rights, we may disclose collected information to relevant authorities. In cases of mergers, acquisitions, or restructuring, your data may be transferred as part of the business assets. HomeTouch is committed to safeguarding your information and ensures that any such transfer complies with applicable laws.',
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 16.0),
              Text(
                'Third-Party Links and Services',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                'HomeTouch may include links to third-party websites or services. We are not responsible for their privacy practices, and users are encouraged to review their respective policies.',
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 16.0),
              Text(
                'Additional Rights for Residents',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                "Residents of certain jurisdictions, such as California and New York, have additional rights regarding the collection and use of their personal data. For example, California residents may request access to the categories of personal information shared with third parties and opt out of certain disclosures. Similarly, New York City residents can opt out of sharing their customer data with merchants. If you have specific concerns or wish to exercise your rights, please contact us at the details provided below.",
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 16.0),
              Text(
                'Policy Updates',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Text(
                  "HomeTouch reserves the right to modify this Privacy Policy at any time. Updates will be posted on our website and app, and continued use of our platform constitutes your acknowledgment and agreement to the revised terms.",
                  textAlign: TextAlign.justify,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
