import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class SelectLocationPage extends StatefulWidget {
  const SelectLocationPage({super.key});

  @override
  _SelectLocationPageState createState() => _SelectLocationPageState();
}

class _SelectLocationPageState extends State<SelectLocationPage> {
  late GoogleMapController _mapController;
  CameraPosition _initialCameraPosition =
      const CameraPosition(target: LatLng(0, 0), zoom: 16);
  LatLng _currentLocation = const LatLng(0, 0);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location services are disabled.")));
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Location permissions are permanently denied.")));
      return;
    }
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permissions are denied.")));
        return;
      }
    }
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _initialCameraPosition =
          CameraPosition(target: _currentLocation, zoom: 16);
    });
    _mapController.animateCamera(CameraUpdate.newLatLng(_currentLocation));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Location',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFBF0000),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: (controller) => _mapController = controller,
            markers: {
              Marker(
                markerId: const MarkerId('selected'),
                position: _currentLocation,
              ),
            },
            onCameraMove: (position) {
              setState(() {
                _currentLocation = position.target;
              });
            },
          ),
          Positioned(
            bottom: 20,
            left: 130,
            right: 130,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'latitude': _currentLocation.latitude,
                  'longitude': _currentLocation.longitude,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBF0000),
              ),
              child: const Text(
                'Select Location',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
