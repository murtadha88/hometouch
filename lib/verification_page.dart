import 'package:flutter/material.dart';
import 'new_password_page.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;

class VerificationPage extends StatefulWidget {
  final String email; // Pass the user's email from ResetPasswordPage
  final String
      verificationCode; // Pass the verification code from ResetPasswordPage

  const VerificationPage({
    super.key,
    required this.email,
    required this.verificationCode,
  });

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());
  bool _isCodeValid = true;
  late String _currentVerificationCode;

  @override
  void initState() {
    super.initState();
    _currentVerificationCode = widget.verificationCode;
    focusNodes[0].requestFocus();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String _generateNewVerificationCode() {
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

  Future<void> _resendCode() async {
    final newCode = _generateNewVerificationCode();
    setState(() {
      _currentVerificationCode = newCode;
    });

    await sendEmailWithMailjet(widget.email, newCode);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New verification code sent to ${widget.email}.'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _verifyCode() {
    final enteredCode =
        _controllers.map((controller) => controller.text).join();

    if (enteredCode == _currentVerificationCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification successful!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NewPasswordPage()),
      );
    } else {
      setState(() {
        _isCodeValid = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid verification code.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        const Center(
                          child: Text(
                            'Enter Verification Number',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(6, (index) {
                            return SizedBox(
                              width: 40,
                              child: TextField(
                                controller: _controllers[index],
                                focusNode: focusNodes[index],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                maxLength: 1,
                                decoration: InputDecoration(
                                  counterText: '',
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  errorText: _isCodeValid ? null : '',
                                ),
                                onChanged: (value) {
                                  if (value.isNotEmpty && index < 5) {
                                    focusNodes[index + 1].requestFocus();
                                  } else if (value.isEmpty && index > 0) {
                                    focusNodes[index - 1].requestFocus();
                                  }
                                  if (index == 5 && value.isNotEmpty) {
                                    _verifyCode();
                                  }
                                },
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: _resendCode,
                            child: const Text(
                              'Send Again?',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFFBF0000),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
