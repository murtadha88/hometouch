import 'package:flutter/material.dart';
import 'new_password_page.dart';

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

  @override
  void initState() {
    super.initState();
    focusNodes[0].requestFocus(); // Focus on the first input box
  }

  @override
  void dispose() {
    // Dispose controllers and focus nodes
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  // Verify the user-entered code
  void _verifyCode() {
    // Collect the code entered by the user
    final enteredCode =
        _controllers.map((controller) => controller.text).join();

    if (enteredCode == widget.verificationCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification successful!'),
          backgroundColor: Colors.green,
        ),
      );
      // Navigate to the New Password Page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NewPasswordPage()),
      );
    } else {
      setState(() {
        _isCodeValid = false; // Mark the code as invalid
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Enter Verification Number',
                style: TextStyle(
                  fontSize: 24,
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
                  width: 50,
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
                      errorText:
                          _isCodeValid ? null : '', // Error display logic
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        focusNodes[index + 1]
                            .requestFocus(); // Move to next field
                      } else if (value.isEmpty && index > 0) {
                        focusNodes[index - 1]
                            .requestFocus(); // Move to previous field
                      }
                      // If last field is filled, verify automatically
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
                onTap: () {
                  // Optionally show a message that the code was sent previously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Verification code was sent to ${widget.email}.'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                child: const Text(
                  'Send Again?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
