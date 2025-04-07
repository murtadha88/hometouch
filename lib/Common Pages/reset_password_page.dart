import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        _isEmailValid = signInMethods.isNotEmpty;
      });

      if (_isEmailValid) {
        _errorMessage = null;
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
      _isEmailValid = true;
    });
  }

  Future<void> _sendResetEmail() async {
    if (_formKey.currentState!.validate()) {
      await _checkEmailExists(_emailController.text.trim());
      if (!_isEmailValid) return;

      try {
        await _auth.sendPasswordResetEmail(
          email: _emailController.text.trim(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Password reset email sent to ${_emailController.text.trim()}.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Optionally, navigate back to the login page:
        Navigator.pop(context);
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.message}"),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                      onPressed: _isButtonDisabled ? null : _sendResetEmail,
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
                        'Reset Password',
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
