import 'dart:ui';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf_render/pdf_render.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:hometouch/Common%20Pages/select_location_page.dart';
import '../Customer View/pravicy_policy_page.dart';
import '../Customer View/term_of_services_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class CreateAccountPage extends StatefulWidget {
  final String role;
  const CreateAccountPage({Key? key, this.role = 'customer'}) : super(key: key);

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _locationController = TextEditingController();
  Map<String, double>? _locationData;

  final List<String> _allCategories = [
    "Burger",
    "Pizza",
    "Pasta",
    "Arab",
    "Seafood",
    "Dessert",
    "Drinks",
    "Breakfast"
  ];
  List<String> _selectedCategories = [];
  String? _selectedVendorType;
  String? _logoUrl;
  bool _twoPeriods = false;
  TimeOfDay? _openTime1;
  TimeOfDay? _closeTime1;
  TimeOfDay? _openTime2;
  TimeOfDay? _closeTime2;
  bool _hasCRNumber = false;
  final _crNumberController = TextEditingController();

  String? _driverLicenseUrl;
  String? _carOwnershipUrl;

  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _termsAccepted = false;
  bool _showErrors = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _locationController.dispose();
    _crNumberController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return widget.role == 'vendor'
          ? 'Business name is required.'
          : 'Name is required.';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required.';
    if (!RegExp(r'^\d{8}$').hasMatch(value))
      return 'Enter a valid 8-digit phone number.';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value))
      return 'Please enter a valid email.';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < 8) return 'Password must be at least 8 characters.';
    if (!RegExp(r'[a-z]').hasMatch(value))
      return 'Password must include at least one lowercase letter.';
    if (!RegExp(r'[A-Z]').hasMatch(value))
      return 'Password must include at least one uppercase letter.';
    if (!RegExp(r'[0-9]').hasMatch(value))
      return 'Password must contain at least one number.';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]').hasMatch(value))
      return 'Password must include at least one special character.';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Confirm password is required.';
    if (value != _passwordController.text) return 'Passwords do not match.';
    return null;
  }

  String? _validateCategories() {
    if (_selectedCategories.isEmpty)
      return 'Please select at least one category.';
    return null;
  }

  String? _validateVendorType() {
    if (_selectedVendorType == null || _selectedVendorType!.isEmpty)
      return 'Please select a vendor type.';
    return null;
  }

  String? _validateLogo() {
    if (_logoUrl == null || _logoUrl!.isEmpty)
      return 'Please upload your logo.';
    return null;
  }

  String? _validateLocation(String? value) {
    if (value == null || value.isEmpty) return 'Location is required.';
    return null;
  }

  String? _validateDriverLicense() {
    if (_driverLicenseUrl == null || _driverLicenseUrl!.isEmpty)
      return 'Please upload your driver license.';
    return null;
  }

  String? _validateCarOwnership() {
    if (_carOwnershipUrl == null || _carOwnershipUrl!.isEmpty)
      return 'Please upload your car ownership card.';
    return null;
  }

  Future<File?> convertPdfToImage(File pdfFile) async {
    try {
      final doc = await PdfDocument.openFile(pdfFile.path);
      final page = await doc.getPage(1);
      final pageImage = await page.render(
        width: page.width.toInt(),
        height: page.height.toInt(),
      );
      final image = await pageImage.createImageIfNotAvailable();
      final imageBytes = await image.toByteData(format: ImageByteFormat.png);

      if (imageBytes == null) return null;

      final tempDir = await getTemporaryDirectory();
      final imagePath =
          '${tempDir.path}/converted_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageBytes.buffer.asUint8List());
      return imageFile;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to convert PDF to image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  Future<String?> _uploadImage(File file) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("https://api.imgur.com/3/upload"),
      );
      request.headers['Authorization'] = 'Client-ID ca25aec45d48f73';
      request.files.add(await http.MultipartFile.fromPath('image', file.path));
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseData);
      if (jsonResponse['success'] == true) {
        return jsonResponse['data']['link'];
      } else {
        throw Exception("Failed to upload image");
      }
    } catch (e) {
      print("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  Future<void> _pickAndUploadFile(Function(String) onUploadComplete) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'pdf'],
    );
    if (result == null) return;
    PlatformFile platformFile = result.files.first;
    if (platformFile.path == null) return;
    File file = File(platformFile.path!);
    String? imageUrl = await _uploadFile(file);
    if (imageUrl != null) {
      onUploadComplete(imageUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Unsupported file type. Please upload an image or PDF.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _uploadFile(File file) async {
    String extension = file.path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
      return _uploadImage(file);
    } else if (extension == 'pdf') {
      File? imageFile = await convertPdfToImage(file);
      if (imageFile != null) {
        return _uploadImage(imageFile);
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  Future<TimeOfDay?> _pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    return picked;
  }

  Future<void> _handleCreateAccount() async {
    setState(() {
      _showErrors = true;
    });
    if (!_formKey.currentState!.validate()) return;

    if (widget.role == 'vendor') {
      if (_validateCategories() != null ||
          _validateVendorType() != null ||
          _validateLogo() != null ||
          _validateLocation(_locationController.text) != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please complete all required vendor fields.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_openTime1 == null || _closeTime1 == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please set your operating hours for period 1.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_twoPeriods && (_openTime2 == null || _closeTime2 == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please set your operating hours for period 2.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_hasCRNumber && _crNumberController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Please enter your Commercial Registration (CR) Number.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    if (widget.role == 'driver') {
      if (_validateDriverLicense() != null || _validateCarOwnership() != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Please upload your driver license and car ownership card.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please accept the Terms of Service and Privacy Policy.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final email = _emailController.text.trim();
      final signInMethods =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (signInMethods.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Email already exists. Please use a different email.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: _passwordController.text,
      );
      final String userId = userCredential.user!.uid;

      Map<String, dynamic> requestData = {
        'Name': _nameController.text,
        'Email': _emailController.text.trim(),
        'Phone': _phoneController.text,
        'Role': widget.role == 'vendor'
            ? 'Vendor'
            : widget.role == 'driver'
                ? 'Driver'
                : 'Customer',
        'Accepted': null,
      };

      if (widget.role == 'vendor') {
        requestData.addAll({
          'Category': _selectedCategories,
          'Vendor_Type': _selectedVendorType,
          'Logo': _logoUrl,
          'Location': _locationData != null
              ? GeoPoint(
                  _locationData!['latitude']!, _locationData!['longitude']!)
              : null,
          'Open_Time_Period1':
              _openTime1 != null ? _openTime1!.format(context) : null,
          'Close_Time_Period1':
              _closeTime1 != null ? _closeTime1!.format(context) : null,
          'Two_Periods': _twoPeriods,
          'Open_Time_Period2': _twoPeriods && _openTime2 != null
              ? _openTime2!.format(context)
              : null,
          'Close_Time_Period2': _twoPeriods && _closeTime2 != null
              ? _closeTime2!.format(context)
              : null,
          'CR_Number': _hasCRNumber ? _crNumberController.text : null,
        });
      } else if (widget.role == 'driver') {
        requestData.addAll({
          'Driver_License': _driverLicenseUrl,
          'Car_Ownership': _carOwnershipUrl,
          'Location': null,
        });
      } else {
        await FirebaseFirestore.instance
            .collection('Customer')
            .doc(userId)
            .set({
          'Customer_ID': userId,
          'Name': _nameController.text,
          'Phone': _phoneController.text,
          'Email': _emailController.text.trim(),
          'Loyalty_Points': 0,
          'Photo': null,
        });
      }

      if (widget.role != 'customer') {
        await FirebaseFirestore.instance
            .collection('request')
            .doc(userId)
            .set(requestData);
      }

      _showSuccessDialog();

      if (widget.role == 'customer') {
        Future.delayed(const Duration(seconds: 3), () {
          Navigator.pop(context);
          Navigator.pop(context);
        });
      }
    } catch (e) {
      print('Error creating user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign-up failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    final isCustomer = widget.role == 'customer';
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            vertical: screenHeight * 0.03,
            horizontal: screenWidth * 0.05,
          ),
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
                isCustomer ? 'Sign Up Success' : 'Request Received',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                isCustomer
                    ? 'Please wait. You will be directed to the login page.'
                    : 'Your request has been submitted successfully!\n\n'
                        'Please wait for our response to join us.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.w300,
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              if (isCustomer)
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFBF0000)),
                )
              else
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Return to login
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBF0000),
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.02,
                      horizontal: screenWidth * 0.1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
  double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  @override
  Widget build(BuildContext context) {
    final double sWidth = screenWidth(context);
    final double sHeight = screenHeight(context);

    String headingText = 'Create Account';
    String subHeadingText =
        'Create an account to start looking for the food you like in HomeTouch';
    if (widget.role == 'vendor') {
      headingText = 'Join Us';
      subHeadingText = 'Join us to succeed in your business with HomeTouch';
    } else if (widget.role == 'driver') {
      headingText = 'Join Us';
      subHeadingText = 'Join us and drive your future with HomeTouch';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: sWidth * 0.05),
            child: Form(
              key: _formKey,
              autovalidateMode: _showErrors
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: sHeight * 0.03),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    headingText,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: sHeight * 0.01),
                  Text(
                    subHeadingText,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: sHeight * 0.04),
                  _buildInputField(
                      widget.role == 'vendor' ? 'Business Name' : 'Name',
                      _nameController,
                      false,
                      _validateName,
                      sWidth),
                  SizedBox(height: sHeight * 0.03),
                  _buildInputField(
                      'Phone', _phoneController, false, _validatePhone, sWidth),
                  SizedBox(height: sHeight * 0.03),
                  _buildInputField(
                      'Email', _emailController, false, _validateEmail, sWidth),
                  SizedBox(height: sHeight * 0.03),
                  _buildInputField('Password', _passwordController, true,
                      _validatePassword, sWidth),
                  SizedBox(height: sHeight * 0.03),
                  _buildInputField(
                      'Confirm Password',
                      _confirmPasswordController,
                      true,
                      _validateConfirmPassword,
                      sWidth),
                  SizedBox(height: sHeight * 0.03),
                  if (widget.role == 'vendor') ...[
                    _buildVendorTypeDropdown(sWidth),
                    SizedBox(height: sHeight * 0.03),
                    _buildCategorySelector(sWidth),
                    SizedBox(height: sHeight * 0.03),
                    _buildLogoUploader(sWidth, sHeight),
                    SizedBox(height: sHeight * 0.03),
                    _buildLocationPicker(sWidth),
                    SizedBox(height: sHeight * 0.03),
                    _buildTimeSection(sWidth, sHeight),
                    SizedBox(height: sHeight * 0.03),
                    _buildCRSection(sWidth, sHeight),
                    SizedBox(height: sHeight * 0.03),
                  ],
                  if (widget.role == 'driver') ...[
                    _buildDriverLicenseUploader(sWidth, sHeight),
                    SizedBox(height: sHeight * 0.03),
                    _buildCarOwnershipUploader(sWidth, sHeight),
                    SizedBox(height: sHeight * 0.03),
                  ],
                  Row(
                    children: [
                      Checkbox(
                        value: _termsAccepted,
                        onChanged: (value) {
                          setState(() {
                            _termsAccepted = value!;
                          });
                        },
                        activeColor: const Color(0xFFBF0000),
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            text: 'I Agree with ',
                            style: const TextStyle(color: Colors.black),
                            children: [
                              TextSpan(
                                text: 'Terms of Service',
                                style: const TextStyle(
                                  color: Color(0xFFBF0000),
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              TermsOfServicePage()),
                                    );
                                  },
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: const TextStyle(
                                  color: Color(0xFFBF0000),
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              PrivacyPolicy()),
                                    );
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: sHeight * 0.01),
                  ElevatedButton(
                    onPressed: _handleCreateAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBF0000),
                      padding: EdgeInsets.symmetric(vertical: sHeight * 0.02),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      minimumSize: Size(sWidth, sHeight * 0.07),
                    ),
                    child: Text(
                      widget.role == 'customer' ? 'Sign up' : 'Request to Join',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: sHeight * 0.04),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    bool isPassword,
    String? Function(String?) validator,
    double screenWidth,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: '$label ',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            children: const [
              TextSpan(text: '*', style: TextStyle(color: Colors.red))
            ],
          ),
        ),
        SizedBox(height: screenWidth * 0.01),
        FormField<String>(
          validator: validator,
          builder: (FormFieldState<String> field) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    color: Colors.grey[200],
                    border: Border.all(
                      color: Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: screenWidth * 0.03,
                        offset: Offset(screenWidth * 0.01, screenWidth * 0.01),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: controller,
                    obscureText: isPassword ? _obscurePassword : false,
                    decoration: InputDecoration(
                      hintText: isPassword
                          ? 'Enter your password'
                          : 'Enter your ${label.toLowerCase()}',
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: screenWidth * 0.04,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: screenWidth * 0.03,
                        horizontal: screenWidth * 0.04,
                      ),
                      border: InputBorder.none,
                      suffixIcon: isPassword
                          ? IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      field.didChange(value);
                    },
                  ),
                ),
                if (field.hasError)
                  Padding(
                    padding: EdgeInsets.only(top: screenWidth * 0.01),
                    child: Text(
                      field.errorText ?? '',
                      style: const TextStyle(
                        color: Color(0xFFBF0000),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildLocationPicker(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Location ',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            children: const [
              TextSpan(text: '*', style: TextStyle(color: Colors.red))
            ],
          ),
        ),
        SizedBox(height: screenWidth * 0.01),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SelectLocationPage()),
              );
              if (result != null) {
                setState(() {
                  _locationData = Map<String, double>.from(result);
                  _locationController.text = "Location Saved!";
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBF0000),
              padding: EdgeInsets.symmetric(
                  vertical: screenWidth * 0.025,
                  horizontal: screenWidth * 0.03),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              minimumSize: Size(screenWidth * 0.3, screenWidth * 0.03),
            ),
            child: Text(
              _locationController.text.isEmpty
                  ? 'Select Location'
                  : _locationController.text,
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Category ',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            children: const [
              TextSpan(text: '*', style: TextStyle(color: Colors.red))
            ],
          ),
        ),
        SizedBox(height: screenWidth * 0.01),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.start,
          children: _allCategories.map((cat) {
            bool isSelected = _selectedCategories.contains(cat);
            return FilterChip(
              label: Text(cat),
              selected: isSelected,
              showCheckmark: false,
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFFBF0000),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFFBF0000),
              ),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Color(0xFFBF0000)),
                borderRadius: BorderRadius.circular(8),
              ),
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _selectedCategories.add(cat);
                  } else {
                    _selectedCategories.remove(cat);
                  }
                });
              },
            );
          }).toList(),
        ),
        if (_showErrors && _validateCategories() != null)
          Padding(
            padding: EdgeInsets.only(top: screenWidth * 0.01),
            child: Text(
              _validateCategories()!,
              style: const TextStyle(color: Color(0xFFBF0000), fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildVendorTypeDropdown(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Vendor Type ',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            children: const [
              TextSpan(text: '*', style: TextStyle(color: Colors.red))
            ],
          ),
        ),
        SizedBox(height: screenWidth * 0.01),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
            color: Colors.grey[200],
            border: Border.all(
              color: Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: screenWidth * 0.03,
                offset: Offset(screenWidth * 0.01, screenWidth * 0.01),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedVendorType,
            items: ['Homemade', 'Food Truck']
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  ),
                )
                .toList(),
            onChanged: (val) {
              setState(() {
                _selectedVendorType = val;
              });
            },
            decoration: InputDecoration(
              hintText: 'Select your vendor type',
              hintStyle: TextStyle(
                color: Colors.grey,
                fontSize: screenWidth * 0.04,
              ),
              contentPadding: EdgeInsets.symmetric(
                vertical: screenWidth * 0.03,
                horizontal: screenWidth * 0.04,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        if (_showErrors && _validateVendorType() != null)
          Padding(
            padding: EdgeInsets.only(top: screenWidth * 0.01),
            child: Text(
              _validateVendorType()!,
              style: const TextStyle(color: Color(0xFFBF0000), fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildLogoUploader(double screenWidth, double screenHeight) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: 'Logo ',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              children: const [
                TextSpan(text: '*', style: TextStyle(color: Colors.red))
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          _logoUrl != null
              ? Image.network(
                  _logoUrl!,
                  width: screenWidth * 0.3,
                  height: screenWidth * 0.3,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: screenWidth * 0.3,
                  height: screenWidth * 0.3,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, color: Colors.white),
                ),
          SizedBox(height: screenHeight * 0.01),
          ElevatedButton(
            onPressed: () {
              _pickAndUploadFile((url) {
                setState(() {
                  _logoUrl = url;
                });
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBF0000),
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              minimumSize: Size(screenWidth * 0.3, screenHeight * 0.03),
            ),
            child: const Text(
              'Upload Logo',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            "You can upload only PDF or image and it should be only 1 page",
            style: TextStyle(
              color: Colors.grey,
              fontSize: screenWidth * 0.035,
            ),
          ),
          if (_showErrors && _validateLogo() != null)
            Padding(
              padding: EdgeInsets.only(top: screenWidth * 0.01),
              child: Text(
                _validateLogo()!,
                style: const TextStyle(color: Color(0xFFBF0000), fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeSection(double screenWidth, double screenHeight) {
    final ButtonStyle timeButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFBF0000),
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      minimumSize: Size(screenWidth * 0.3, screenHeight * 0.03),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Do you run your business in two periods?',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.bold,
          ),
        ),
        Column(
          children: [
            Row(
              children: [
                Radio<bool>(
                  value: false,
                  groupValue: _twoPeriods,
                  activeColor: const Color(0xFFBF0000),
                  onChanged: (val) {
                    setState(() {
                      _twoPeriods = val!;
                    });
                  },
                ),
                const Text('No'),
                const SizedBox(width: 20),
                Radio<bool>(
                  value: true,
                  groupValue: _twoPeriods,
                  activeColor: const Color(0xFFBF0000),
                  onChanged: (val) {
                    setState(() {
                      _twoPeriods = val!;
                    });
                  },
                ),
                const Text('Yes'),
              ],
            )
          ],
        ),
        SizedBox(height: screenHeight * 0.01),
        Text(
          'Period 1:',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04),
        ),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: timeButtonStyle,
                onPressed: () async {
                  TimeOfDay? picked = await _pickTime();
                  if (picked != null) {
                    setState(() {
                      _openTime1 = picked;
                    });
                  }
                },
                child: Text(
                  _openTime1 != null
                      ? 'Open: ${_openTime1!.format(context)}'
                      : 'Select Open Time',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(width: screenWidth * 0.04),
            Expanded(
              child: ElevatedButton(
                style: timeButtonStyle,
                onPressed: () async {
                  TimeOfDay? picked = await _pickTime();
                  if (picked != null) {
                    setState(() {
                      _closeTime1 = picked;
                    });
                  }
                },
                child: Text(
                  _closeTime1 != null
                      ? 'Close: ${_closeTime1!.format(context)}'
                      : 'Select Close Time',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: screenHeight * 0.02),
        if (_twoPeriods) ...[
          Text(
            'Period 2:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.04,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: timeButtonStyle,
                  onPressed: () async {
                    TimeOfDay? picked = await _pickTime();
                    if (picked != null) {
                      setState(() {
                        _openTime2 = picked;
                      });
                    }
                  },
                  child: Text(
                    _openTime2 != null
                        ? 'Open: ${_openTime2!.format(context)}'
                        : 'Select Open Time',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
              Expanded(
                child: ElevatedButton(
                  style: timeButtonStyle,
                  onPressed: () async {
                    TimeOfDay? picked = await _pickTime();
                    if (picked != null) {
                      setState(() {
                        _closeTime2 = picked;
                      });
                    }
                  },
                  child: Text(
                    _closeTime2 != null
                        ? 'Close: ${_closeTime2!.format(context)}'
                        : 'Select Close Time',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCRSection(double screenWidth, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Do you have a CR Number?',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.bold,
          ),
        ),
        Column(
          children: [
            Row(
              children: [
                Radio<bool>(
                  value: false,
                  groupValue: _hasCRNumber,
                  activeColor: const Color(0xFFBF0000),
                  onChanged: (val) {
                    setState(() {
                      _hasCRNumber = val!;
                    });
                  },
                ),
                const Text('No'),
                const SizedBox(width: 20),
                Radio<bool>(
                  value: true,
                  groupValue: _hasCRNumber,
                  activeColor: const Color(0xFFBF0000),
                  onChanged: (val) {
                    setState(() {
                      _hasCRNumber = val!;
                    });
                  },
                ),
                const Text('Yes'),
              ],
            )
          ],
        ),
        SizedBox(height: screenHeight * 0.01),
        if (_hasCRNumber) _buildCRUploader(screenWidth, screenHeight),
      ],
    );
  }

  Widget _buildCRUploader(double screenWidth, double screenHeight) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: 'Commercial Registration (CR) ',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              children: const [
                TextSpan(text: '*', style: TextStyle(color: Colors.red))
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          _crNumberController.text.isNotEmpty
              ? Image.network(
                  _crNumberController.text,
                  width: screenWidth * 0.3,
                  height: screenWidth * 0.3,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: screenWidth * 0.3,
                  height: screenWidth * 0.3,
                  color: Colors.grey[300],
                  child: const Icon(Icons.file_present, color: Colors.white),
                ),
          SizedBox(height: screenHeight * 0.01),
          ElevatedButton(
            onPressed: () {
              _pickAndUploadFile((url) {
                setState(() {
                  _crNumberController.text = url;
                });
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBF0000),
              padding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.01,
                  horizontal: screenWidth * 0.03),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              minimumSize: Size(screenWidth * 0.3, screenHeight * 0.03),
            ),
            child: const Text(
              'Upload CR Document',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            "You can upload only PDF or image and it should be only 1 page",
            style: TextStyle(
              color: Colors.grey,
              fontSize: screenWidth * 0.035,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverLicenseUploader(double screenWidth, double screenHeight) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: 'Driver License ',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              children: const [
                TextSpan(text: '*', style: TextStyle(color: Colors.red))
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          _driverLicenseUrl != null
              ? Image.network(
                  _driverLicenseUrl!,
                  width: screenWidth * 0.3,
                  height: screenWidth * 0.3,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: screenWidth * 0.3,
                  height: screenWidth * 0.3,
                  color: Colors.grey[300],
                  child: const Icon(Icons.file_present, color: Colors.white),
                ),
          SizedBox(height: screenHeight * 0.01),
          ElevatedButton(
            onPressed: () {
              _pickAndUploadFile((url) {
                setState(() {
                  _driverLicenseUrl = url;
                });
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBF0000),
              padding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.01,
                  horizontal: screenWidth * 0.03),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              minimumSize: Size(screenWidth * 0.3, screenHeight * 0.03),
            ),
            child: const Text(
              'Upload Driver License',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            "You can upload only PDF or image and it should be only 1 page",
            style: TextStyle(
              color: Colors.grey,
              fontSize: screenWidth * 0.035,
            ),
          ),
          if (_showErrors && _validateDriverLicense() != null)
            Padding(
              padding: EdgeInsets.only(top: screenWidth * 0.01),
              child: Text(
                _validateDriverLicense()!,
                style: const TextStyle(color: Color(0xFFBF0000), fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCarOwnershipUploader(double screenWidth, double screenHeight) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: 'Car Ownership Card ',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              children: const [
                TextSpan(text: '*', style: TextStyle(color: Colors.red))
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          _carOwnershipUrl != null
              ? Image.network(
                  _carOwnershipUrl!,
                  width: screenWidth * 0.3,
                  height: screenWidth * 0.3,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: screenWidth * 0.3,
                  height: screenWidth * 0.3,
                  color: Colors.grey[300],
                  child: const Icon(Icons.file_present, color: Colors.white),
                ),
          SizedBox(height: screenHeight * 0.01),
          ElevatedButton(
            onPressed: () {
              _pickAndUploadFile((url) {
                setState(() {
                  _carOwnershipUrl = url;
                });
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBF0000),
              padding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.01,
                  horizontal: screenWidth * 0.03),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              minimumSize: Size(screenWidth * 0.3, screenHeight * 0.03),
            ),
            child: const Text(
              'Upload Car Ownership Card',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            "You can upload only PDF or image and it should be only 1 page",
            style: TextStyle(
              color: Colors.grey,
              fontSize: screenWidth * 0.035,
            ),
          ),
          if (_showErrors && _validateCarOwnership() != null)
            Padding(
              padding: EdgeInsets.only(top: screenWidth * 0.01),
              child: Text(
                _validateCarOwnership()!,
                style: const TextStyle(color: Color(0xFFBF0000), fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
