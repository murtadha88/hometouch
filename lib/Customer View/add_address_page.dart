import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddAddressPage extends StatefulWidget {
  const AddAddressPage({super.key});

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  String selectedType = 'Building';

  final _buildingFormKey = GlobalKey<FormState>();
  final _apartmentFormKey = GlobalKey<FormState>();
  final _officeFormKey = GlobalKey<FormState>();

  final _buildingController = TextEditingController();
  final _roadController = TextEditingController();
  final _blockController = TextEditingController();

  final _apartmentController = TextEditingController();
  final _floorController = TextEditingController();

  final _officeController = TextEditingController();
  final _companyController = TextEditingController();

  final _addressNameControllerBuilding = TextEditingController();
  final _addressNameControllerApartment = TextEditingController();
  final _addressNameControllerOffice = TextEditingController();

  final _additionalDirectionControllerBuilding = TextEditingController();
  final _additionalDirectionControllerApartment = TextEditingController();
  final _additionalDirectionControllerOffice = TextEditingController();

  late GoogleMapController _mapController;
  late CameraPosition _initialCameraPosition;
  LatLng _currentLocation = LatLng(0, 0);

  @override
  void initState() {
    super.initState();
    _initialCameraPosition =
        CameraPosition(target: _currentLocation, zoom: 16.0);
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _buildingController.dispose();
    _roadController.dispose();
    _blockController.dispose();
    _apartmentController.dispose();
    _floorController.dispose();
    _officeController.dispose();
    _companyController.dispose();
    _addressNameControllerBuilding.dispose();
    _addressNameControllerApartment.dispose();
    _addressNameControllerOffice.dispose();
    _additionalDirectionControllerBuilding.dispose();
    _additionalDirectionControllerApartment.dispose();
    _additionalDirectionControllerOffice.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Location services are disabled.")));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Location permissions are permanently denied.")));
      return;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Location permissions are denied.")));
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _initialCameraPosition =
          CameraPosition(target: _currentLocation, zoom: 14.0);

      _mapController.animateCamera(CameraUpdate.newLatLng(_currentLocation));
    });
  }

  Future<void> _saveAddress() async {
    if (selectedType == 'Building') {
      if (!_buildingFormKey.currentState!.validate()) return;
    } else if (selectedType == 'Apartment') {
      if (!_apartmentFormKey.currentState!.validate()) return;
    } else if (selectedType == 'Office') {
      if (!_officeFormKey.currentState!.validate()) return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final customerRef =
        FirebaseFirestore.instance.collection('Customer').doc(user.uid);
    final addressRef = customerRef.collection('address').doc();

    final data = <String, dynamic>{
      'Name': selectedType == 'Building'
          ? _addressNameControllerBuilding.text.trim()
          : selectedType == 'Apartment'
              ? _addressNameControllerApartment.text.trim()
              : _addressNameControllerOffice.text.trim(),
      'Building': int.tryParse(_buildingController.text) ?? 0,
      'Road': int.tryParse(_roadController.text) ?? 0,
      'Block': int.tryParse(_blockController.text) ?? 0,
      'Location': GeoPoint(
        _currentLocation.latitude,
        _currentLocation.longitude,
      ),
      'AdditionalDirection': (selectedType == 'Building'
                  ? _additionalDirectionControllerBuilding.text
                  : selectedType == 'Apartment'
                      ? _additionalDirectionControllerApartment.text
                      : _additionalDirectionControllerOffice.text)
              .trim()
              .isEmpty
          ? null
          : (selectedType == 'Building'
              ? _additionalDirectionControllerBuilding.text.trim()
              : selectedType == 'Apartment'
                  ? _additionalDirectionControllerApartment.text.trim()
                  : _additionalDirectionControllerOffice.text.trim()),
    };

    if (selectedType == 'Apartment') {
      if (_apartmentController.text.trim().isNotEmpty) {
        data['Apartment'] = int.tryParse(_apartmentController.text) ??
            _apartmentController.text.trim();
      }
      if (_floorController.text.trim().isNotEmpty) {
        data['Floor'] =
            int.tryParse(_floorController.text) ?? _floorController.text.trim();
      }
    }

    if (selectedType == 'Office') {
      if (_officeController.text.trim().isNotEmpty) {
        data['Office_No'] = int.tryParse(_officeController.text) ??
            _officeController.text.trim();
      }
      if (_floorController.text.trim().isNotEmpty) {
        data['Floor'] =
            int.tryParse(_floorController.text) ?? _floorController.text.trim();
      }
      if (_companyController.text.trim().isNotEmpty) {
        data['Company_Name'] = _companyController.text.trim();
      }
    }

    data.removeWhere((key, value) => value == null);

    await addressRef.set(data);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
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
              'Add Address',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: screenHeight * 0.027,
              ),
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(screenHeight * 0.002),
            child: Divider(
                thickness: screenHeight * 0.001, color: Colors.grey[300]),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(bottom: keyboardHeight),
          child: Column(
            children: [
              SizedBox(
                height: screenHeight * 0.4,
                width: double.infinity,
                child: GoogleMap(
                  initialCameraPosition: _initialCameraPosition,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    _mapController.animateCamera(
                        CameraUpdate.newLatLng(_currentLocation));
                  },
                  markers: {
                    Marker(
                        markerId: MarkerId("current_location"),
                        position: _currentLocation),
                  },
                  onCameraMove: (CameraPosition position) {
                    setState(() {
                      _currentLocation = position.target;
                    });
                  },
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['Building', 'Apartment', 'Office'].map((type) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedType = type;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                          vertical: screenHeight * 0.015,
                        ),
                        decoration: BoxDecoration(
                          color: selectedType == type
                              ? const Color(0xFFBF0000)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            color: selectedType == type
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (selectedType == 'Building') ...[
                      _buildBuildingForm(),
                    ],
                    if (selectedType == 'Apartment') ...[
                      _buildApartmentForm(),
                    ],
                    if (selectedType == 'Office') ...[
                      _buildOfficeForm(),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBuildingForm() {
    return Form(
      key: _buildingFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  label: 'Building',
                  hintText: '0000',
                  controller: _buildingController,
                  isRequired: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInputField(
                  label: 'Road',
                  hintText: '0000',
                  controller: _roadController,
                  isRequired: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInputField(
                  label: 'Block',
                  hintText: '0000',
                  controller: _blockController,
                  isRequired: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInputField(
            label: 'Address Name',
            hintText: 'Enter your address label',
            controller: _addressNameControllerBuilding,
            isRequired: true,
          ),
          const SizedBox(height: 20),
          _buildInputField(
            label: 'Additional Direction (optional)',
            hintText: 'Optional',
            controller: _additionalDirectionControllerBuilding,
            isRequired: false,
          ),
          const SizedBox(height: 20),
          _buildAddAddressButton(_buildingFormKey),
        ],
      ),
    );
  }

  Widget _buildApartmentForm() {
    return Form(
      key: _apartmentFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  label: 'Building',
                  hintText: '0000',
                  controller: _buildingController,
                  isRequired: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInputField(
                  label: 'Road',
                  hintText: '0000',
                  controller: _roadController,
                  isRequired: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInputField(
                  label: 'Block',
                  hintText: '0000',
                  controller: _blockController,
                  isRequired: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  label: 'Apartment',
                  hintText: '0000',
                  controller: _apartmentController,
                  isRequired: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInputField(
                  label: 'Floor',
                  hintText: '0000',
                  controller: _floorController,
                  isRequired: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInputField(
            label: 'Address Name',
            hintText: 'Enter your address label',
            controller: _addressNameControllerApartment,
            isRequired: true,
          ),
          const SizedBox(height: 20),
          _buildInputField(
            label: 'Additional Direction (optional)',
            hintText: 'Optional',
            controller: _additionalDirectionControllerApartment,
            isRequired: false,
          ),
          const SizedBox(height: 20),
          _buildAddAddressButton(_apartmentFormKey),
        ],
      ),
    );
  }

  Widget _buildOfficeForm() {
    return Form(
      key: _officeFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  label: 'Building',
                  hintText: '0000',
                  controller: _buildingController,
                  isRequired: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInputField(
                  label: 'Road',
                  hintText: '0000',
                  controller: _roadController,
                  isRequired: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInputField(
                  label: 'Block',
                  hintText: '0000',
                  controller: _blockController,
                  isRequired: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  label: 'Office',
                  hintText: '0000',
                  controller: _officeController,
                  isRequired: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInputField(
                  label: 'Floor',
                  hintText: '0000',
                  controller: _floorController,
                  isRequired: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInputField(
            label: 'Company',
            hintText: 'Company name',
            controller: _companyController,
            isRequired: true,
          ),
          const SizedBox(height: 20),
          _buildInputField(
            label: 'Address Name',
            hintText: 'Enter your address label',
            controller: _addressNameControllerOffice,
            isRequired: true,
          ),
          const SizedBox(height: 20),
          _buildInputField(
            label: 'Additional Direction (optional)',
            hintText: 'Optional',
            controller: _additionalDirectionControllerOffice,
            isRequired: false,
          ),
          const SizedBox(height: 20),
          _buildAddAddressButton(_officeFormKey),
        ],
      ),
    );
  }

  Widget _buildAddAddressButton(GlobalKey<FormState> formKey) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFBF0000),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: _saveAddress,
        child: const Text(
          'Save Address',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required bool isRequired,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black,
            ),
            children: isRequired
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red),
                    ),
                  ]
                : [],
          ),
        ),
        const SizedBox(height: 5),
        FormField<String>(
          validator: isRequired
              ? (value) {
                  if (controller.text.isEmpty) {
                    return 'Required';
                  }
                  return null;
                }
              : null,
          builder: (fieldState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: controller,
                    onChanged: (_) {
                      fieldState.didChange(controller.text);
                    },
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                if (fieldState.hasError) ...[
                  const SizedBox(height: 5),
                  Text(
                    fieldState.errorText ?? '',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
