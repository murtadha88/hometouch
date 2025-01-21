import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:hometouch/reset_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool rememberMe = false;
  bool _obscureText = true;
  bool emailError = false;
  bool passwordError = false;

  void toggleRememberMe() {
    setState(() {
      rememberMe = !rememberMe;
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  Future<void> loginUserWithEmailAndPassword() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(vertical: 25, horizontal: 20),
            title: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(0xFFBF0000),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: 50,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Login Success',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  alignment: Alignment.center,
                  child: Text(
                    'Please wait. You will be directed to the home page',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 15),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFBF0000)),
                ),
              ],
            ),
          );
        },
      );

      Future.delayed(Duration(seconds: 3), () {
        Navigator.of(context).pop();
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        print(e.code);
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
        SnackBar(
            content: Text('An unexpected error occurred. Please try again.')),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Sign-in successful!')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(e.message ?? 'An error occurred during Google Sign-in')),
      );
    }
  }

  Future<UserCredential> signInWithFacebook() async {
    final LoginResult loginResult = await FacebookAuth.instance.login();
    final OAuthCredential facebookAuthCredential =
        FacebookAuthProvider.credential(loginResult.accessToken!.tokenString);

    return FirebaseAuth.instance.signInWithCredential(facebookAuthCredential);
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
              SizedBox(height: screenHeight * 0.12),
              Text(
                'Login',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: screenWidth * 0.11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: screenHeight * 0.05),
              _buildInputField('Email', _emailController, false, emailError),
              SizedBox(height: screenHeight * 0.02),
              _buildInputField(
                  'Password', _passwordController, true, passwordError),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: rememberMe,
                        onChanged: (value) {
                          toggleRememberMe();
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Text(
                        'Remember me',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: screenWidth * 0.03,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ResetPasswordPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'Forget password?',
                      style: TextStyle(
                        color: Color(0xFFBF0000),
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.02),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    height: 35,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.black,
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 0, 0, 0)
                              .withOpacity(0.5),
                          blurRadius: 3,
                          offset: Offset(2, 4),
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
                      minimumSize: Size(double.infinity, 40),
                      backgroundColor: Color(0xFFBF0000),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.03),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: screenWidth * 0.03,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      'SIGN UP',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: screenWidth * 0.03,
                        color: Color(0xFFBF0000),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.04),
              Row(
                children: [
                  Expanded(
                    child: const Divider(
                      thickness: 1,
                      color: Colors.black,
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: screenWidth * 0.03,
                        color: Color(0xFFBF0000),
                      ),
                    ),
                  ),
                  Expanded(
                    child: const Divider(
                      thickness: 1,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.04),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: screenWidth * 0.05,
                runSpacing: screenHeight * 0.01,
                children: [
                  _buildSocialIcon('https://i.imgur.com/tOB1B2j.png'),
                  _buildSocialIcon('https://i.imgur.com/oY1eSza.png'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller,
      bool isPassword, bool hasError) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.grey[200],
            border: Border.all(
              color: hasError ? Color(0xFFBF0000) : Colors.transparent,
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
                fontSize: 12,
              ),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              border: InputBorder.none,
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(_obscureText
                          ? Icons.visibility_off
                          : Icons.visibility),
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

  Widget _buildSocialIcon(String imageUrl) {
    return GestureDetector(
      onTap: () async {
        if (imageUrl == 'https://i.imgur.com/tOB1B2j.png') {
          signInWithGoogle();
        } else if (imageUrl == 'https://i.imgur.com/oY1eSza.png') {
          signInWithFacebook();
        }
      },
      child: Container(
        width: 50,
        height: 50,
        margin: EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
