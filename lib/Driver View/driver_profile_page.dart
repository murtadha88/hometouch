import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class DriverProfilePage extends StatefulWidget {
  const DriverProfilePage({Key? key}) : super(key: key);

  @override
  _DriverProfilePageState createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  bool isEditable = false;
  bool isLoading = true;

  String driverName = 'Loading...';
  String driverEmail = 'Loading...';
  String driverPhone = 'Not Available';
  String? driverPhotoUrl;

  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _driverEmailController = TextEditingController();
  final TextEditingController _driverPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getDriverInfo();
  }

  Future<void> _getDriverInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('Driver')
            .doc(user.uid)
            .get();

        setState(() {
          driverName = doc['Name'] ?? 'Unknown';
          driverEmail = doc['Email'] ?? 'Not Available';
          driverPhone = doc['Phone'] ?? 'Not Available';
          driverPhotoUrl = doc['Photo'] ?? "";
          _driverNameController.text = driverName;
          _driverEmailController.text = driverEmail;
          _driverPhoneController.text = driverPhone;
          isLoading = false;
        });
      } catch (e) {
        print("Error fetching driver info: $e");
        setState(() {
          isLoading = false;
        });
      }
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
                horizontal: screenWidth * 0.05,
              ),
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
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.black)),
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

  Future<void> _updateDriverInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        String newEmail = _driverEmailController.text.trim();
        String currentAuthEmail = user.email ?? '';

        if (newEmail != currentAuthEmail) {
          bool reauthSuccess =
              await _showReauthenticateDialog(currentAuthEmail);
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
            .collection('Driver')
            .doc(user.uid)
            .update({
          'Name': _driverNameController.text,
          'Email': _driverEmailController.text,
          'Phone': _driverPhoneController.text,
        });
        setState(() {
          driverName = _driverNameController.text;
          driverEmail = _driverEmailController.text;
          driverPhone = _driverPhoneController.text;
          isEditable = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print("Error updating driver info: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update driver profile.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadPhoto() async {
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

        await FirebaseFirestore.instance
            .collection('Driver')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({'Photo': imageUrl});

        setState(() {
          driverPhotoUrl = imageUrl;
        });
      } else {
        throw Exception("Failed to upload image");
      }
    } catch (e) {
      print("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to upload image. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
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
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFBF0000),
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
              'Driver Profile',
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
                thickness: screenHeight * 0.001, color: Colors.grey[300]),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: const Color(0xFFBF0000),
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
                          backgroundImage: driverPhotoUrl != null &&
                                  driverPhotoUrl!.isNotEmpty
                              ? NetworkImage(driverPhotoUrl!)
                              : NetworkImage(
                                  'https://i.imgur.com/OtAn7hT.jpeg'),
                        ),
                        Positioned(
                          bottom: screenHeight * 0.01,
                          right: screenWidth * 0.02,
                          child: GestureDetector(
                            onTap: _uploadPhoto,
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
                      driverName,
                      style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Center(child: Text(driverEmail)),
                  SizedBox(height: screenHeight * 0.04),
                  _buildEditableTextField('Name', _driverNameController, true,
                      screenWidth, screenHeight),
                  _buildEditableTextField('Email', _driverEmailController,
                      false, screenWidth, screenHeight),
                  _buildEditableTextField('Phone', _driverPhoneController,
                      false, screenWidth, screenHeight),
                  SizedBox(height: screenHeight * 0.02),
                  isEditable
                      ? _buildSaveCancelButtons(screenWidth, screenHeight)
                      : Container(),
                ],
              ),
            ),
    );
  }

  Widget _buildEditableTextField(String label, TextEditingController controller,
      bool showEditIcon, double screenWidth, double screenHeight) {
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
                      _driverNameController.text = driverName;
                      _driverEmailController.text = driverEmail;
                      _driverPhoneController.text = driverPhone;
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
              controller: controller,
              readOnly: !isEditable,
              decoration: const InputDecoration(border: InputBorder.none),
              style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  color: isEditable ? Colors.black : Colors.grey),
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
            onPressed: _updateDriverInfo,
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
                _driverNameController.text = driverName;
                _driverEmailController.text = driverEmail;
                _driverPhoneController.text = driverPhone;
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
