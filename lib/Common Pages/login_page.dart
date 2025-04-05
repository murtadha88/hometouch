import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hometouch/Admin%20View/admin_requests_page.dart';
import 'package:hometouch/Common%20Pages/reset_password_page.dart';
import 'package:hometouch/Driver%20View/driver_dashboard_page.dart';
import 'package:hometouch/Vendor%20View/vendor_dashboard_page.dart';
import 'sign_up_page.dart';
import '../Customer View/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  final String role;

  const LoginPage({super.key, this.role = 'customer'});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _obscureText = true;
  bool emailError = false;
  bool passwordError = false;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  Future<void> loginUserWithEmailAndPassword() async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      User? user = userCredential.user;

      SharedPreferences prefs = await SharedPreferences.getInstance();

      QuerySnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('admin')
          .where('Email', isEqualTo: user!.email)
          .get();
      if (adminSnapshot.docs.isNotEmpty) {
        await prefs.setString('role', 'admin');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminRequestsPage()),
        );
        return;
      }

      if (widget.role == 'vendor') {
        QuerySnapshot qs = await FirebaseFirestore.instance
            .collection('vendor')
            .where('Email', isEqualTo: user.email)
            .get();
        if (qs.docs.isEmpty) {
          await _auth.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Your email is not registered as a vendor")),
          );
          return;
        }
        await prefs.setString('role', 'vendor');
      } else if (widget.role == 'driver') {
        QuerySnapshot qs = await FirebaseFirestore.instance
            .collection('Driver')
            .where('Email', isEqualTo: user.email)
            .get();
        if (qs.docs.isEmpty) {
          await _auth.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Your email is not registered as a driver")),
          );
          return;
        }
        await prefs.setString('role', 'driver');
      } else {
        await prefs.setString('role', 'customer');
      }

      await prefs.setBool('isLoggedIn', true);

      _showSuccessDialog();

      Future.delayed(const Duration(seconds: 3), () {
        String role = prefs.getString('role') ?? 'customer';
        if (role == 'vendor') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const VendorDashboard()),
          );
        } else if (role == 'driver') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DriverDashboard()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeTouchScreen()),
          );
        }
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'channel-error') {
          emailError = true;
          passwordError = true;
        }
        if (e.code == 'user-not-found') {
          emailError = true;
          passwordError = false;
        } else if (e.code == 'wrong-password') {
          emailError = false;
          passwordError = true;
        } else if (e.code == 'invalid-email') {
          emailError = true;
          passwordError = false;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('An unexpected error occurred. Please try again.')),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    if (widget.role != 'customer') return;
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      await _saveUserToFirestore(userCredential.user);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      _showSuccessDialog();

      Future.delayed(const Duration(seconds: 3), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeTouchScreen()),
        );
      });
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(e.message ?? 'An error occurred during Google Sign-in')),
      );
    }
  }

  Future<void> signInWithFacebook() async {
    if (widget.role != 'customer') return;
    try {
      final LoginResult loginResult = await FacebookAuth.instance.login();
      if (loginResult.status != LoginStatus.success) return;

      final OAuthCredential facebookAuthCredential =
          FacebookAuthProvider.credential(loginResult.accessToken!.tokenString);

      UserCredential userCredential =
          await _auth.signInWithCredential(facebookAuthCredential);

      await _saveUserToFirestore(userCredential.user);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      _showSuccessDialog();

      Future.delayed(const Duration(seconds: 3), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeTouchScreen()),
        );
      });
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(e.message ?? 'An error occurred during Facebook Sign-in')),
      );
    }
  }

  Future<void> _saveUserToFirestore(User? user) async {
    if (user == null) return;

    if (widget.role == 'customer') {
      final userRef =
          FirebaseFirestore.instance.collection('Customer').doc(user.uid);
      await userRef.set({
        'Customer_ID': user.uid,
        'Name': user.displayName ?? 'No Name',
        'Email': user.email ?? 'No Email',
        'Phone': user.phoneNumber,
        'Photo': null,
        "Loyalty_Points": 0
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        return AlertDialog(
          backgroundColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.03, horizontal: screenWidth * 0.05),
          title: Container(
            padding: EdgeInsets.all(screenWidth * 0.05),
            decoration: const BoxDecoration(
              color: Color(0xFFBF0000),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              color: Colors.white,
              size: screenWidth * 0.12,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Login Success',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Container(
                alignment: Alignment.center,
                child: Text(
                  'Please wait. You will be directed to the home page',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.w300,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              CircularProgressIndicator(
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFFBF0000)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.08),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                  color: Colors.black,
                ),
              ),
              SizedBox(height: screenHeight * 0.04),
              Text(
                'Login',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: screenWidth * 0.1,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: screenHeight * 0.05),
              _buildInputField('Email', _emailController, false, emailError,
                  screenWidth, screenHeight),
              SizedBox(height: screenHeight * 0.02),
              _buildInputField('Password', _passwordController, true,
                  passwordError, screenWidth, screenHeight),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ResetPasswordPage(),
                        ),
                      );
                    },
                    child: Text(
                      'Forget password?',
                      style: TextStyle(
                        color: const Color(0xFFBF0000),
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    height: screenHeight * 0.07,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.black,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 3,
                          offset: const Offset(2, 4),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: loginUserWithEmailAndPassword,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      minimumSize: Size(double.infinity, screenHeight * 0.07),
                      backgroundColor: const Color(0xFFBF0000),
                    ),
                    child: Text(
                      'Login',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.03),
              if (widget.role == 'customer') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: screenWidth * 0.035,
                        color: Colors.black,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CreateAccountPage(role: widget.role),
                          ),
                        );
                      },
                      child: Text(
                        'SIGN UP',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: screenWidth * 0.035,
                          color: const Color(0xFFBF0000),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.05),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: 1,
                        color: Colors.black,
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: screenWidth * 0.03,
                          color: const Color(0xFFBF0000),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        thickness: 1,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.03),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: screenWidth * 0.05,
                  children: [
                    _buildSocialIcon('assets/google.png', screenWidth),
                    _buildSocialIcon('assets/facebock.png', screenWidth),
                  ],
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: screenWidth * 0.035,
                        color: Colors.black,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CreateAccountPage(role: widget.role),
                          ),
                        );
                      },
                      child: Text(
                        'JOIN US',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: screenWidth * 0.035,
                          color: const Color(0xFFBF0000),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller,
      bool isPassword, bool hasError, double screenWidth, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: screenHeight * 0.005),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.grey[200],
            border: Border.all(
              color: hasError ? const Color(0xFFBF0000) : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 3,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword ? _obscureText : false,
            decoration: InputDecoration(
              hintText:
                  isPassword ? 'Enter your password' : 'example@gmail.com',
              hintStyle: TextStyle(
                color: Colors.grey,
                fontSize: screenWidth * 0.04,
              ),
              contentPadding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.015,
                horizontal: screenWidth * 0.03,
              ),
              border: InputBorder.none,
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                        size: screenWidth * 0.05,
                      ),
                      color: Colors.grey,
                      onPressed: _togglePasswordVisibility,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialIcon(String imageUrl, double screenWidth) {
    return GestureDetector(
      onTap: () async {
        if (imageUrl == 'assets/google.png') {
          signInWithGoogle();
        } else if (imageUrl == 'assets/facebock.png') {
          signInWithFacebook();
        }
      },
      child: Container(
        width: screenWidth * 0.12,
        height: screenWidth * 0.12,
        margin: EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
          image: DecorationImage(
            image: AssetImage(imageUrl),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
