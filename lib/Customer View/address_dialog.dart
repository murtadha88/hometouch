import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_address_page.dart';

class Address {
  final String name;
  final int building;
  final int road;
  final int block;
  final int? floor;
  final int? apartment;
  final int? office;
  final String? companyName;
  final GeoPoint location;

  Address({
    required this.name,
    required this.building,
    required this.road,
    required this.block,
    this.floor,
    this.apartment,
    this.office,
    this.companyName,
    required this.location,
  });

  String getFullAddress() {
    String address = "$name, Building $building, Road $road, Block $block";

    if (floor != null && floor != 0) address += ", Floor $floor";
    if (apartment != null && apartment != 0)
      address += ", Apartment $apartment";
    if (office != null && office != 0) address += ", Office $office";
    if (companyName != null && companyName != '0')
      address += ", Company: $companyName";

    return address;
  }

  factory Address.fromFirestore(Map<String, dynamic> data) {
    return Address(
      name: data['Name'],
      building: int.tryParse(data['Building'].toString()) ?? 0,
      road: int.tryParse(data['Road'].toString()) ?? 0,
      block: int.tryParse(data['Block'].toString()) ?? 0,
      floor:
          data['Floor'] != null ? int.tryParse(data['Floor'].toString()) : null,
      apartment: data['Apartment'] != null
          ? int.tryParse(data['Apartment'].toString())
          : null,
      office: data['Office'] != null
          ? int.tryParse(data['Office'].toString())
          : null,
      companyName: data['Company_Name'],
      location: data['Location'] ?? GeoPoint(0.0, 0.0),
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
    fetchAddresses();
  }

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
            ...addresses.isNotEmpty
                ? addresses
                    .map((address) => _buildAddressField(address: address))
                : [
                    Center(
                      child: Text(
                        'No saved address',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
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

  Widget _buildAddressField({required Address address}) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context, address);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: widget.screenWidth * 0.09,
            vertical: widget.screenHeight * 0.01),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              address.name,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: widget.screenHeight * 0.022,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: widget.screenHeight * 0.005),
            Text(
              address.getFullAddress(),
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
      ),
    );
  }
}
