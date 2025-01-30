import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_address_page.dart';

class Address {
  final String name;
  final int building; // Changed to int for numerical data
  final int road; // Changed to int for numerical data
  final int block; // Changed to int for numerical data
  final int? floor; // Changed to int for numerical data
  final int? apartment; // Changed to int for numerical data
  final int? office; // Changed to int for numerical data
  final String? companyName;

  Address({
    required this.name,
    required this.building,
    required this.road,
    required this.block,
    this.floor,
    this.apartment,
    this.office,
    this.companyName,
  });

  // Create the full address string
  String getFullAddress() {
    String address = "$name, Building $building, Road $road, Block $block";

    // Only add fields if they are not null or 0
    if (floor != null && floor != 0) address += ", Floor $floor";
    if (apartment != null && apartment != 0)
      address += ", Apartment $apartment";
    if (office != null && office != 0) address += ", Office $office";
    if (companyName != null && companyName != '0')
      address += ", Company: $companyName";

    return address;
  }

  // Factory method to create an Address from Firestore document data
  factory Address.fromFirestore(Map<String, dynamic> data) {
    return Address(
      name: data['Name'],
      building: data['Building'] is int
          ? data['Building']
          : int.tryParse(data['Building'].toString()) ??
              0, // Ensure it's an int
      road: data['Road'] is int
          ? data['Road']
          : int.tryParse(data['Road'].toString()) ?? 0, // Ensure it's an int
      block: data['Block'] is int
          ? data['Block']
          : int.tryParse(data['Block'].toString()) ?? 0, // Ensure it's an int
      floor: data['Floor'] is int
          ? data['Floor']
          : int.tryParse(data['Floor'].toString()), // Ensure it's an int
      apartment: data['Apartment'] is int
          ? data['Apartment']
          : int.tryParse(data['Apartment'].toString()), // Ensure it's an int
      office: data['Office'] is int
          ? data['Office']
          : int.tryParse(data['Office'].toString()), // Ensure it's an int
      companyName: data['Company_Name'],
    );
  }
}

class AddressDialog extends StatefulWidget {
  final double screenWidth;
  final double screenHeight;
  final VoidCallback onClose;

  const AddressDialog({
    Key? key,
    required this.screenWidth,
    required this.screenHeight,
    required this.onClose,
  }) : super(key: key);

  @override
  _AddressDialogState createState() => _AddressDialogState();
}

class _AddressDialogState extends State<AddressDialog> {
  List<Address> addresses = [];

  @override
  void initState() {
    super.initState();
    fetchAddresses(); // Fetch addresses when dialog is initialized
  }

  // Fetch the addresses from Firestore
  Future<void> fetchAddresses() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final customerRef =
            FirebaseFirestore.instance.collection('Customer').doc(user.uid);
        final addressSnapshot = await customerRef.collection('address').get();

        setState(() {
          addresses = addressSnapshot.docs
              .map((doc) => Address.fromFirestore(doc.data()))
              .toList();
        });
      }
    } catch (e) {
      print("Error fetching addresses: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      child: Container(
        width: screenWidth,
        padding: EdgeInsets.only(bottom: screenHeight * 0.1),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 234, 234, 234),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(55),
            topRight: Radius.circular(55),
          ),
          border: const Border(
            top: BorderSide(color: Color(0xFFBF0000), width: 4),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(
                  right: screenWidth * 0.05,
                  top: screenHeight * 0.01,
                ),
                child: IconButton(
                  icon: Icon(Icons.close,
                      color: Color.fromARGB(255, 226, 62, 62),
                      size: screenHeight * 0.03),
                  onPressed: widget.onClose,
                ),
              ),
            ),
            // Dynamically build the address fields if addresses exist
            ...addresses.isNotEmpty
                ? addresses.map((address) => _buildAddressField(
                      title: address.name,
                      address: address
                          .getFullAddress(), // Get the full address dynamically
                    ))
                : [
                    Center(
                      child: Text(
                        'No saved address', // Message to show when there are no addresses
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ], // Show a loader if no addresses are available
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.09,
                  vertical: screenHeight * 0.02),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Add Address",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: screenHeight * 0.022,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AddAddressPage()),
                            );
                          }
                        },
                        child: Icon(Icons.add,
                            color: Color.fromARGB(255, 226, 62, 62),
                            size: screenHeight * 0.03),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Container(
                    width: double.infinity,
                    height: 2,
                    color: const Color(0xFFBF0000),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressField({required String title, required String address}) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: widget.screenWidth * 0.09,
          vertical: widget.screenHeight * 0.01),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: widget.screenHeight * 0.022,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: widget.screenHeight * 0.005),
          Text(
            address,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: widget.screenHeight * 0.014,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
          SizedBox(height: widget.screenHeight * 0.008),
          Container(
            width: double.infinity,
            height: 2,
            color: const Color(0xFFBF0000),
          ),
        ],
      ),
    );
  }
}
