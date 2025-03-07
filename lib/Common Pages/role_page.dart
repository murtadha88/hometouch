import 'package:flutter/material.dart';
import 'login_page.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({Key? key}) : super(key: key);

  Widget _buildRoleButton({
    required BuildContext context,
    required String role,
    required String title,
    required String imageAsset,
  }) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.01,
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LoginPage(role: role),
            ),
          );
        },
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7.0),
          ),
          color: Colors.white,
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.03),
            child: Row(
              children: [
                Container(
                  width: screenWidth * 0.25,
                  height: screenHeight * 0.12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7.0),
                    image: DecorationImage(
                      image: AssetImage(imageAsset),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: screenWidth * 0.055,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.11),
              Text(
                'Select Your Role',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: screenWidth * 0.08,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                'Please let us know who you are to continue',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: screenWidth * 0.04,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.06),
              _buildRoleButton(
                context: context,
                role: 'customer',
                title: 'Customer',
                imageAsset: 'assets/customer.png',
              ),
              _buildRoleButton(
                context: context,
                role: 'vendor',
                title: 'Vendor',
                imageAsset: 'assets/homeFoodTruck.png',
              ),
              _buildRoleButton(
                context: context,
                role: 'driver',
                title: 'Driver',
                imageAsset: 'assets/driver.png',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
