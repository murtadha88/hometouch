import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class VendorProfilePage extends StatefulWidget {
  const VendorProfilePage({Key? key}) : super(key: key);

  @override
  _VendorProfilePageState createState() => _VendorProfilePageState();
}

class _VendorProfilePageState extends State<VendorProfilePage> {
  bool isEditable = false;
  bool isLoading = true;

  String vendorName = '';
  String vendorEmail = '';
  String vendorPhone = '';
  String? vendorLogo;

  bool twoPeriods = false;
  String openTime1 = '';
  String closeTime1 = '';
  String openTime2 = '';
  String closeTime2 = '';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _openTime1Controller = TextEditingController();
  final TextEditingController _closeTime1Controller = TextEditingController();
  final TextEditingController _openTime2Controller = TextEditingController();
  final TextEditingController _closeTime2Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getVendorInfo();
  }

  Future<void> _getVendorInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('vendor')
          .doc(user.uid)
          .get();

      setState(() {
        vendorName = doc['Name'] ?? 'Unknown';
        vendorEmail = doc['Email'] ?? 'Not Available';
        vendorPhone = doc['Phone'] ?? 'Not Available';
        vendorLogo = doc['Logo'] ?? "";
        twoPeriods = doc['Two_Periods'] ?? false;

        openTime1 = doc['Open_Time_Period1'] ?? '';
        closeTime1 = doc['Close_Time_Period1'] ?? '';
        openTime2 = doc['Open_Time_Period2'] ?? '';
        closeTime2 = doc['Close_Time_Period2'] ?? '';

        _nameController.text = vendorName;
        _emailController.text = vendorEmail;
        _phoneController.text = vendorPhone;
        _openTime1Controller.text = openTime1;
        _closeTime1Controller.text = closeTime1;
        _openTime2Controller.text = openTime2;
        _closeTime2Controller.text = closeTime2;

        isLoading = false;
      });
    } catch (e) {
      print("Error fetching vendor info: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<bool> _showReauthenticateDialog(String currentAuthEmail) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        TextEditingController passwordController = TextEditingController();
        String? errorMessage;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.03,
                  horizontal: screenWidth * 0.05),
              title: Container(
                padding: EdgeInsets.all(screenWidth * 0.05),
                decoration: const BoxDecoration(
                  color: Color(0xFFBF0000),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock,
                  color: Colors.white,
                  size: screenWidth * 0.12,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Reauthenticate',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    'Please enter your password to update your email:',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w300,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      errorText: errorMessage,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: Colors.grey,
                  ),
                  onPressed: () async {
                    String password = passwordController.text.trim();
                    if (password.isEmpty) {
                      setState(() {
                        errorMessage = 'Password cannot be empty.';
                      });
                      return;
                    }
                    AuthCredential credential = EmailAuthProvider.credential(
                      email: currentAuthEmail,
                      password: password,
                    );
                    try {
                      await FirebaseAuth.instance.currentUser!
                          .reauthenticateWithCredential(credential);
                      Navigator.of(context).pop(true);
                    } on FirebaseAuthException catch (e) {
                      setState(() {
                        if (e.code == 'wrong-password') {
                          errorMessage = 'The password is incorrect.';
                        } else {
                          errorMessage =
                              'Reauthentication failed: ${e.message}';
                        }
                      });
                    }
                  },
                  child: const Text(
                    'Confirm',
                    style: TextStyle(
                      color: Color(0xFFBF0000),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((value) => value ?? false);
  }

  Future<void> _updateVendorInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      String newEmail = _emailController.text.trim();
      String currentAuthEmail = user.email ?? '';

      if (newEmail != currentAuthEmail) {
        bool reauthSuccess = await _showReauthenticateDialog(currentAuthEmail);
        if (!reauthSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Reauthentication cancelled. Email was not updated.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        await user.updateEmail(newEmail);
      }

      await FirebaseFirestore.instance
          .collection('vendor')
          .doc(user.uid)
          .update({
        'Name': _nameController.text,
        'Email': newEmail,
        'Phone': _phoneController.text,
        'Two_Periods': twoPeriods,
        'Open_Time_Period1': _openTime1Controller.text,
        'Close_Time_Period1': _closeTime1Controller.text,
        'Open_Time_Period2': _openTime2Controller.text,
        'Close_Time_Period2': _closeTime2Controller.text,
      });

      setState(() {
        vendorName = _nameController.text;
        vendorEmail = newEmail;
        vendorPhone = _phoneController.text;
        openTime1 = _openTime1Controller.text;
        closeTime1 = _closeTime1Controller.text;
        openTime2 = _openTime2Controller.text;
        closeTime2 = _closeTime2Controller.text;
        isEditable = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Error updating vendor info: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    File file = File(pickedFile.path);

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
        String imageUrl = jsonResponse['data']['link'];

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('vendor')
              .doc(user.uid)
              .update({'Logo': imageUrl});
        }
        setState(() {
          vendorLogo = imageUrl;
        });
      } else {
        throw Exception("Failed to upload image");
      }
    } catch (e) {
      print("Error uploading logo: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to upload image. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final timeOfDay = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (timeOfDay != null) {
      final formattedTime = timeOfDay.format(context);
      setState(() {
        controller.text = formattedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(screenHeight * 0.09),
        child: AppBar(
          leading: Padding(
            padding: EdgeInsets.only(
                top: screenHeight * 0.025, left: screenWidth * 0.02),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFBF0000),
                ),
                alignment: Alignment.center,
                padding: EdgeInsets.only(
                    top: screenHeight * 0.001, left: screenWidth * 0.02),
                child: Icon(Icons.arrow_back_ios,
                    color: Colors.white, size: screenHeight * 0.025),
              ),
            ),
          ),
          title: Padding(
            padding: EdgeInsets.only(top: screenHeight * 0.02),
            child: Text(
              'Vendor Profile',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: screenHeight * 0.027,
              ),
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(screenHeight * 0.002),
            child: Divider(
              thickness: screenHeight * 0.001,
              color: Colors.grey[300],
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFFBF0000),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: screenWidth * 0.2,
                          backgroundColor: Colors.grey[300],
                          backgroundImage:
                              (vendorLogo != null && vendorLogo!.isNotEmpty)
                                  ? NetworkImage(vendorLogo!)
                                  : const NetworkImage(
                                      'https://i.imgur.com/OtAn7hT.jpeg'),
                        ),
                        Positioned(
                          bottom: screenHeight * 0.01,
                          right: screenWidth * 0.02,
                          child: GestureDetector(
                            onTap: _uploadLogo,
                            child: CircleAvatar(
                              radius: screenWidth * 0.06,
                              backgroundColor: Colors.grey[100],
                              child: Icon(
                                Icons.edit,
                                size: screenWidth * 0.05,
                                color: const Color(0xFFBF0000),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Center(
                    child: Text(
                      vendorName,
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Center(
                      child: Text(vendorEmail,
                          style: const TextStyle(color: Colors.black))),
                  SizedBox(height: screenHeight * 0.04),
                  _buildEditableTextField(
                    label: 'Name',
                    controller: _nameController,
                    showEditIcon: true,
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                  ),
                  _buildEditableTextField(
                    label: 'Email',
                    controller: _emailController,
                    showEditIcon: false,
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                  ),
                  _buildEditableTextField(
                    label: 'Phone',
                    controller: _phoneController,
                    showEditIcon: false,
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Two Periods?',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.045,
                        ),
                      ),
                      Switch(
                        activeColor: const Color(0xFFBF0000),
                        value: twoPeriods,
                        onChanged: isEditable
                            ? (val) {
                                setState(() {
                                  twoPeriods = val;
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  _buildTimePickerRow(
                    label: 'Open Time 1',
                    controller: _openTime1Controller,
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                  ),
                  _buildTimePickerRow(
                    label: 'Close Time 1',
                    controller: _closeTime1Controller,
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                  ),
                  if (twoPeriods) ...[
                    SizedBox(height: screenHeight * 0.02),
                    _buildTimePickerRow(
                      label: 'Open Time 2',
                      controller: _openTime2Controller,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    _buildTimePickerRow(
                      label: 'Close Time 2',
                      controller: _closeTime2Controller,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                  ],
                  SizedBox(height: screenHeight * 0.02),
                  isEditable
                      ? _buildSaveCancelButtons(screenWidth, screenHeight)
                      : Container(),
                ],
              ),
            ),
    );
  }

  Widget _buildEditableTextField({
    required String label,
    required TextEditingController controller,
    required bool showEditIcon,
    required double screenWidth,
    required double screenHeight,
  }) {
    setState(() {
      _nameController.text = vendorName;
      _emailController.text = vendorEmail;
      _phoneController.text = vendorPhone;
    });

    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.045,
                ),
              ),
              if (showEditIcon)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _nameController.text = vendorName;
                      _emailController.text = vendorEmail;
                      _phoneController.text = vendorPhone;
                      isEditable = true;
                    });
                  },
                  child: Icon(
                    Icons.edit_note_outlined,
                    color: const Color(0xFFBF0000),
                    size: screenWidth * 0.07,
                  ),
                ),
            ],
          ),
          SizedBox(height: screenHeight * 0.01),
          Container(
            height: screenHeight * 0.065,
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFFBF0000),
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: TextField(
              key: ValueKey(controller.text),
              controller: controller,
              readOnly: !isEditable,
              decoration: const InputDecoration(border: InputBorder.none),
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: isEditable ? Colors.black : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerRow({
    required String label,
    required TextEditingController controller,
    required double screenWidth,
    required double screenHeight,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.045,
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          Container(
            height: screenHeight * 0.065,
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFFBF0000),
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Expanded(
                  child: isEditable
                      ? TextField(
                          key: ValueKey(controller.text),
                          controller: controller,
                          readOnly: true,
                          decoration:
                              const InputDecoration(border: InputBorder.none),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        )
                      : TextField(
                          key: ValueKey(controller.text),
                          controller: controller,
                          readOnly: true,
                          decoration:
                              const InputDecoration(border: InputBorder.none),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                ),
                if (isEditable)
                  IconButton(
                    icon: const Icon(
                      Icons.access_time,
                      color: Color(0xFFBF0000),
                    ),
                    onPressed: () => _pickTime(controller),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveCancelButtons(double screenWidth, double screenHeight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          flex: 4,
          child: ElevatedButton(
            onPressed: _updateVendorInfo,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBF0000),
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ),
        SizedBox(width: screenWidth * 0.04),
        Expanded(
          flex: 4,
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _nameController.text = vendorName;
                _emailController.text = vendorEmail;
                _phoneController.text = vendorPhone;
                _openTime1Controller.text = openTime1;
                _closeTime1Controller.text = closeTime1;
                _openTime2Controller.text = openTime2;
                _closeTime2Controller.text = closeTime2;
                isEditable = false;
              });
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFBF0000)),
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFFBF0000))),
          ),
        ),
      ],
    );
  }
}
