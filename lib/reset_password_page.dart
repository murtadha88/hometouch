import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'verification_page.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isButtonDisabled = true;
  String? _errorMessage;
  bool _isEmailValid = true;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return "Email field cannot be empty.";
    }
    const emailRegex = r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$';
    if (!RegExp(emailRegex).hasMatch(value)) {
      return "Please enter a valid email address.";
    }
    return null;
  }

  Future<void> _checkEmailExists(String email) async {
    try {
      final signInMethods =
          await _auth.fetchSignInMethodsForEmail(email.trim());
      setState(() {
        _isEmailValid = signInMethods.isNotEmpty; // Check if email exists
      });

      if (_isEmailValid) {
        _errorMessage = null; // Clear any previous error messages
      } else {
        _errorMessage = "This email is not registered.";
      }
    } catch (e) {
      setState(() {
        _isEmailValid = false;
        _errorMessage = "Error checking email: ${e.toString()}";
      });
    }
  }

  void _onEmailChanged(String value) {
    setState(() {
      _isButtonDisabled = _validateEmail(value) != null;
      _errorMessage = _validateEmail(value);
      _isEmailValid = true; // Reset email validation on every change
    });
  }

  String _generateVerificationCode() {
    final random = Random();
    return List.generate(6, (_) => random.nextInt(10).toString()).join();
  }

  Future<void> sendEmailWithMailjet(
      String email, String verificationCode) async {
    final apiKey = '523ea479515a4b4a9d0117d2b0cf2131';
    final apiSecret = '69cd5a711861a632953d078742bb62e0';
    final url = Uri.parse('https://api.mailjet.com/v3.1/send');

    final body = {
      "Messages": [
        {
          "From": {"Email": "hometouch.bahrain@gmail.com", "Name": "HomeTouch"},
          "To": [
            {"Email": email, "Name": "User"}
          ],
          "Subject": "Your Verification Code",
          "TextPart": "Your verification code is $verificationCode",
          "HTMLPart":
              "<h3>Your verification code is <strong>$verificationCode</strong></h3>"
        }
      ]
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization':
            'Basic ${base64Encode(utf8.encode('$apiKey:$apiSecret'))}',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      print("Email sent successfully.");
    } else {
      print("Failed to send email: ${response.statusCode}");
      print("Response body: ${response.body}");
    }
  }

  Future<void> _sendCode() async {
    if (_formKey.currentState!.validate()) {
      await _checkEmailExists(
          _emailController.text.trim()); // Check email exists
      if (!_isEmailValid) return;

      final code = _generateVerificationCode();
      await sendEmailWithMailjet(_emailController.text.trim(), code);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Verification code sent to ${_emailController.text.trim()}.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerificationPage(
            email: _emailController.text.trim(),
            verificationCode: code,
          ),
        ),
      );
    }
  }

  Widget _buildEmailInputField(double screenWidth, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email',
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
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
            color: Colors.grey[200],
            border: Border.all(
              color:
                  !_isEmailValid ? const Color(0xFFBF0000) : Colors.transparent,
              width: screenWidth * 0.005,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: screenWidth * 0.02,
                offset: Offset(screenWidth * 0.01, screenWidth * 0.01),
              ),
            ],
          ),
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'example@gmail.com',
              hintStyle: TextStyle(
                color: Colors.grey,
                fontSize: screenWidth * 0.04,
              ),
              contentPadding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.02,
                horizontal: screenWidth * 0.03,
              ),
              border: InputBorder.none,
            ),
            onChanged: _onEmailChanged,
            validator: _validateEmail,
          ),
        ),
        SizedBox(height: screenHeight * 0.01),
        if (!_isEmailValid && _errorMessage != null)
          Text(
            _errorMessage!,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: screenWidth * 0.03,
              color: const Color(0xFFBF0000),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: Colors.grey[700],
          splashRadius: 20,
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenHeight,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenHeight * 0.05),
                    Center(
                      child: Text(
                        'Reset Password',
                        style: TextStyle(
                          fontSize: screenWidth * 0.09,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    _buildEmailInputField(screenWidth, screenHeight),
                    SizedBox(height: screenHeight * 0.03),
                    ElevatedButton(
                      onPressed: _isButtonDisabled ? null : _sendCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isButtonDisabled
                            ? Colors.grey
                            : const Color(0xFFBF0000),
                        padding:
                            EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(screenWidth * 0.03),
                        ),
                        minimumSize: Size.fromHeight(screenHeight * 0.07),
                      ),
                      child: Text(
                        'Send Code',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
