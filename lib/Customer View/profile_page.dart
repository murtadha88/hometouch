import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hometouch/Customer%20View/address_dialog.dart';
import 'package:hometouch/Common%20Pages/reset_password_page.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditable = false;
  String userName = 'Loading...';
  String userEmail = 'Loading...';
  String userPhone = 'Loading...';

  TextEditingController _userNameController = TextEditingController();
  TextEditingController _userEmailController = TextEditingController();
  TextEditingController _userPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  Future<void> _getUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('Customer')
          .doc(user.uid)
          .get();

      setState(() {
        userName = docSnapshot['Name'] ?? 'Unknown';
        userEmail = docSnapshot['Email'] ?? 'Not Available';
        userPhone = docSnapshot['Phone'] ?? 'Not Available';

        _userNameController.text = userName;
        _userEmailController.text = userEmail;
        _userPhoneController.text = userPhone;
      });
    }
  }

  Future<void> _updateUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('Customer')
            .doc(user.uid)
            .update({
          'Name': _userNameController.text,
          'Email': _userEmailController.text,
          'Phone': _userPhoneController.text
        });

        setState(() {
          userName = _userNameController.text;
          userEmail = _userEmailController.text;
          userPhone = _userPhoneController.text;
          _isEditable = false;
        });
      } catch (e) {
        print('Error updating user info: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

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
              'Profile',
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEditableTextField(
                'Name', _userNameController, true, screenWidth, screenHeight),
            _buildEditableTextField('Email', _userEmailController, false,
                screenWidth, screenHeight),
            _buildEditableTextField('Phone', _userPhoneController, false,
                screenWidth, screenHeight),
            if (!_isEditable) ...[
              _buildListTile(
                'Change Password',
                Icons.lock,
                screenWidth,
                screenHeight,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ResetPasswordPage()),
                  );
                },
              ),
              _buildListTile(
                'Addresses',
                Icons.location_on,
                screenWidth,
                screenHeight,
                () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (BuildContext context) {
                      return AddressDialog(
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                        onClose: () {
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                },
              )
            ],
            if (_isEditable) _buildSaveCancelButtons(screenWidth, screenHeight),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableTextField(String label, TextEditingController controller,
      bool showEditIcon, double screenWidth, double screenHeight) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.02),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.045,
                      ),
                    ),
                    if (showEditIcon)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _userEmailController.text = userEmail;
                            _userNameController.text = userName;
                            _userPhoneController.text = userPhone;
                            _isEditable = !_isEditable;
                          });
                        },
                        child: Icon(
                          Icons.edit_note_outlined,
                          color: Color(0xFFBF0000),
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
                      color: Color(0xFFBF0000),
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _isEditable
                            ? TextField(
                                controller: controller,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: label,
                                  hintStyle: TextStyle(
                                    color: Color.fromARGB(255, 127, 127, 127),
                                    fontSize: screenWidth * 0.04,
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  color: Colors.black,
                                ),
                              )
                            : Text(
                                controller.text,
                                style: TextStyle(
                                  color: Color.fromARGB(255, 127, 127, 127),
                                  fontSize: screenWidth * 0.04,
                                ),
                              ),
                      ),
                    ],
                  ),
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
            onPressed: _updateUserInfo,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFBF0000),
              textStyle: TextStyle(fontWeight: FontWeight.bold),
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.04),
        Expanded(
          flex: 4,
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _userEmailController.text = userEmail;
                _userNameController.text = userName;
                _userPhoneController.text = userPhone;
                _isEditable = false;
              });
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Color(0xFFBF0000)),
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(color: Color(0xFFBF0000)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListTile(
    String title,
    IconData icon,
    double screenWidth,
    double screenHeight,
    void Function()? onTap,
  ) {
    return ListTile(
      contentPadding:
          EdgeInsets.symmetric(vertical: 0, horizontal: screenWidth * 0.04),
      leading: Icon(
        icon,
        color: Color(0xFFBF0000),
        size: screenWidth * 0.06,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Color.fromARGB(255, 0, 0, 0),
          fontSize: screenWidth * 0.04,
        ),
      ),
      trailing: Padding(
        padding: EdgeInsets.only(right: screenWidth * 0.04),
        child: Icon(
          Icons.arrow_forward_ios,
          color: Color(0xFFBF0000),
          size: screenWidth * 0.04,
        ),
      ),
      onTap: onTap,
    );
  }
}
