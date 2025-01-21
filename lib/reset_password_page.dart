import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'verification_page.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isButtonDisabled = true;
  String? _errorMessage;

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

  void _onEmailChanged(String value) {
    setState(() {
      _isButtonDisabled = _validateEmail(value) != null;
      _errorMessage = _validateEmail(value);
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

  Future<void> _sendVerificationCode(String email, String code) async {
    try {
      await sendEmailWithMailjet(email, code);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification code sent to $email.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send verification code.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendCode() async {
    if (_formKey.currentState!.validate()) {
      final code = _generateVerificationCode();

      await _sendVerificationCode(_emailController.text.trim(), code);

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

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final keyboardHeight = mediaQuery.viewInsets.bottom;

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
              minHeight: screenHeight - keyboardHeight,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Center(
                        child: Text(
                          'Reset Password',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      RichText(
                        text: TextSpan(
                          text: 'Email ',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          children: const [
                            TextSpan(
                              text: '*',
                              style: TextStyle(
                                color: Color(0xFFBF0000),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'example@gmail.com',
                          hintStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[200],
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          errorText: _errorMessage,
                        ),
                        onChanged: _onEmailChanged,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isButtonDisabled ? null : _sendCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isButtonDisabled
                              ? Colors.grey
                              : Color(0xFFBF0000),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text(
                          'Send Code',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
