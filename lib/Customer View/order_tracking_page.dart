import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const Color primaryRed = Color(0xFFBF0000);

class OrderTrackingPage extends StatefulWidget {
  final String orderId;

  const OrderTrackingPage({Key? key, required this.orderId}) : super(key: key);

  @override
  _OrderTrackingPageState createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  late GoogleMapController mapController;
  Map<String, dynamic>? orderData;
  Map<String, dynamic>? driverData;
  bool isLoading = true;
  Set<Marker> _markers = {};

  String driverName = "Loading...";
  String driverPhone = "Loading...";
  String driverPhoto = "Loading...";
  LatLng? driverLocation;

  LatLng? customerLocation;
  StreamSubscription<DocumentSnapshot>? _driverLocationSubscription;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  @override
  void dispose() {
    _driverLocationSubscription?.cancel(); // Cancel the subscription
    super.dispose();
  }

  Future<void> _fetchOrderDetails() async {
    try {
      DocumentSnapshot orderSnapshot = await FirebaseFirestore.instance
          .collection("order")
          .doc(widget.orderId)
          .get();

      if (!orderSnapshot.exists) {
        print("❌ Order not found");
        return;
      }

      setState(() {
        orderData = orderSnapshot.data() as Map<String, dynamic>;
        isLoading = false;
      });

      if (orderData?["Driver_ID"] != null &&
          orderData?["Driver_ID"] != "Pending") {
        _fetchDriverDetails(orderData?["Driver_ID"]);
      } else {
        print("❌ No driver assigned yet.");
      }

      if (orderData?["Customer_Address"] != null) {
        final address = orderData?["Customer_Address"];

        if (address["Location"] is GeoPoint) {
          GeoPoint geoPoint = address["Location"];
          customerLocation = LatLng(geoPoint.latitude, geoPoint.longitude);
          _updateCustomerMarker(customerLocation!);
        }
      }
    } catch (e) {
      print("❌ Error fetching order: $e");
    }
  }

  Future<void> _fetchDriverDetails(String driverId) async {
    try {
      _driverLocationSubscription = FirebaseFirestore.instance
          .collection("Driver")
          .doc(driverId)
          .snapshots()
          .listen((driverSnapshot) {
        if (driverSnapshot.exists && driverSnapshot.data() != null) {
          Map<String, dynamic> driverData =
              driverSnapshot.data() as Map<String, dynamic>;

          setState(() {
            this.driverData = driverData;

            driverName = driverData["Name"] ?? "Unknown";
            driverPhone = driverData["Phone"]?.toString() ?? "No phone";
            driverPhoto = driverData["Photo"] ??
                "https://randomuser.me/api/portraits/men/1.jpg";

            if (driverData["Location"] is GeoPoint) {
              GeoPoint location = driverData["Location"];
              driverLocation = LatLng(location.latitude, location.longitude);
              _updateDriverMarker(driverLocation!);
            }
          });
        }
      });
    } catch (e) {
      print("❌ Error fetching driver details: $e");
    }
  }

  Future<BitmapDescriptor> _getDriverMarkerIcon() async {
    return await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(50, 50)),
      'assets/car_pin.png',
    );
  }

  Future<void> _updateDriverMarker(LatLng location) async {
    final BitmapDescriptor customDriverMarker = await _getDriverMarkerIcon();

    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId("driver"),
          position: location,
          icon: customDriverMarker,
          infoWindow: const InfoWindow(title: "Driver Location"),
        ),
      );
    });
  }

  Future<BitmapDescriptor> _getCustomerMarkerIcon() async {
    return await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(50, 50)),
      'assets/customer_pin.png',
    );
  }

  void _updateCustomerMarker(LatLng location) async {
    final BitmapDescriptor customCustomerMarker =
        await _getCustomerMarkerIcon();

    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId("customer"),
          position: location,
          icon: customCustomerMarker,
          infoWindow: const InfoWindow(title: "Customer Location"),
        ),
      );
    });
  }

//   void updateDriverLocation() async {
//   Location location = Location();

//   bool _serviceEnabled = await location.serviceEnabled();
//   if (!_serviceEnabled) {
//     _serviceEnabled = await location.requestService();
//     if (!_serviceEnabled) {
//       print("❌ Location services are disabled.");
//       return;
//     }
//   }

//   PermissionStatus _permissionGranted = await location.hasPermission();
//   if (_permissionGranted == PermissionStatus.denied) {
//     _permissionGranted = await location.requestPermission();
//     if (_permissionGranted != PermissionStatus.granted) {
//       print("❌ Location permissions are denied.");
//       return;
//     }
//   }

//   location.onLocationChanged.listen((LocationData currentLocation) async {
//     if (currentLocation.latitude != null &&
//         currentLocation.longitude != null) {
//       await FirebaseFirestore.instance
//           .collection("Driver")
//           .doc("eJXF01SPCo4QK3UApmpR") // Replace with actual driver ID
//           .update({
//         "Location":
//             GeoPoint(currentLocation.latitude!, currentLocation.longitude!)
//       });
//       print(
//           "📍 Driver Location Updated: ${currentLocation.latitude}, ${currentLocation.longitude}");
//     }
//   });
// }

  @override
  Widget build(BuildContext context) {
    // Obtain screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: primaryRed,
                strokeWidth: screenWidth * 0.015,
              ),
            )
          : Stack(
              children: [
                driverLocation != null
                    ? GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: driverLocation ??
                              customerLocation ??
                              LatLng(26.0, 50.0),
                          zoom: 14,
                        ),
                        markers: _markers,
                        onMapCreated: (controller) {
                          mapController = controller;
                        },
                      )
                    : Center(
                        child: Text(
                          "Driver location not available",
                          style: TextStyle(fontSize: screenWidth * 0.045),
                        ),
                      ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: EdgeInsets.all(
                          screenWidth * 0.06), // Adjust as needed
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryRed,
                          ),
                          padding: EdgeInsets.only(
                              left: screenWidth * 0.052,
                              top: screenWidth * 0.03,
                              right: screenWidth * 0.03,
                              bottom: screenWidth * 0.03),
                          child: Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: screenHeight * 0.025,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                DraggableScrollableSheet(
                  initialChildSize: 0.4,
                  minChildSize: 0.4,
                  maxChildSize: 0.6,
                  builder: (context, scrollController) {
                    return Container(
                      padding: EdgeInsets.all(screenWidth * 0.044),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(screenWidth * 0.055),
                          topRight: Radius.circular(screenWidth * 0.055),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: screenWidth * 0.033,
                            offset: Offset(0, screenHeight * 0.003),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDriverInfo(screenWidth, screenHeight),
                            Divider(
                              height: screenHeight * 0.02,
                              thickness: screenHeight * 0.002,
                            ),
                            _buildOrderStatus(screenWidth, screenHeight),
                            Divider(
                              height: screenHeight * 0.02,
                              thickness: screenHeight * 0.002,
                            ),
                            _buildOrderItems(screenWidth, screenHeight),
                            Divider(
                              height: screenHeight * 0.02,
                              thickness: screenHeight * 0.002,
                            ),
                            Text(
                              "Total: ${orderData?["Total"].toString()} BHD",
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildDriverInfo(double screenWidth, double screenHeight) {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(driverPhoto),
          radius: screenWidth * 0.066,
        ),
        SizedBox(width: screenWidth * 0.033),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                driverName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.044,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: screenHeight * 0.007),
              Text(
                "Phone: $driverPhone",
                style: TextStyle(
                  fontSize: screenWidth * 0.038,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        // Chat icon (white icon, red circle)
        IconButton(
          icon: CircleAvatar(
            backgroundColor: primaryRed,
            radius: screenWidth * 0.06,
            child: Icon(
              Icons.chat,
              color: Colors.white,
              size: screenWidth * 0.06,
            ),
          ),
          onPressed: () {
            // TODO: Navigate to chat page
          },
        ),
        // Call icon (white icon, red circle)
        IconButton(
          icon: CircleAvatar(
            backgroundColor: primaryRed,
            radius: screenWidth * 0.06,
            child: Icon(
              Icons.call,
              color: Colors.white,
              size: screenWidth * 0.06,
            ),
          ),
          onPressed: () async {
            final phone = driverData?["Phone"]?.toString() ?? "";
            if (phone.isNotEmpty) {
              final Uri callUri = Uri(scheme: 'tel', path: phone);
              if (await canLaunchUrl(callUri)) {
                await launchUrl(callUri);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Could not launch phone dialer",
                      style: TextStyle(fontSize: screenWidth * 0.035),
                    ),
                  ),
                );
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildOrderStatus(double screenWidth, double screenHeight) {
    int currentStep;
    final String status = orderData?["Status"] ?? "Order Placed";

    if (status == "Order Placed") {
      currentStep = 1;
    } else if (status == "Preparing") {
      currentStep = 2;
    } else if (status == "On The Way") {
      currentStep = 3;
    } else if (status == "Delivered") {
      currentStep = 4;
    } else {
      currentStep = 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Order Status:",
          style: TextStyle(
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: screenHeight * 0.005),
        _buildModernStatusBar(
          currentStep: currentStep,
          totalSteps: 4,
          screenWidth: screenWidth,
          screenHeight: screenHeight,
        ),
      ],
    );
  }

  Widget _buildModernStatusBar({
    required int currentStep,
    required int totalSteps,
    required double screenWidth,
    required double screenHeight,
  }) {
    final steps = [
      {"label": "Order Placed", "icon": Icons.check_circle},
      {"label": "Preparing", "icon": Icons.restaurant_menu},
      {"label": "On The Way", "icon": Icons.delivery_dining},
      {"label": "Delivered", "icon": Icons.home},
    ];

    List<Widget> rowChildren = [];
    for (int i = 0; i < steps.length; i++) {
      final isCompleted = (i + 1) <= currentStep;
      rowChildren.add(_buildStepIcon(
        steps[i]["icon"] as IconData,
        steps[i]["label"] as String,
        isCompleted,
        screenWidth,
        screenHeight,
      ));
      if (i < steps.length - 1) {
        final dotCompleted = (i + 1) < currentStep;
        rowChildren.add(_buildDottedLine(
          isCompleted: dotCompleted,
          screenWidth: screenWidth,
        ));
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: rowChildren,
      ),
    );
  }

  Widget _buildStepIcon(IconData iconData, String label, bool isCompleted,
      double screenWidth, double screenHeight) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          iconData,
          color: isCompleted ? primaryRed : Colors.grey,
          size: screenWidth * 0.083,
        ),
        SizedBox(height: screenHeight * 0.005),
        Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * 0.033,
            fontWeight: FontWeight.w600,
            color: isCompleted ? primaryRed : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildDottedLine(
      {required bool isCompleted, required double screenWidth}) {
    final Color lineColor = isCompleted ? primaryRed : Colors.grey[400]!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Container(
          width: screenWidth * 0.011,
          height: screenWidth * 0.011,
          margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.005),
          decoration: BoxDecoration(
            color: lineColor,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Widget _buildOrderItems(double screenWidth, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Order Items",
          style: TextStyle(
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.bold,
          ),
        ),
        ...List.generate(
          (orderData?["Items"] as List).length,
          (index) {
            var item = orderData?["Items"][index];
            return Padding(
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.005),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Text(item["name"],
                          style: TextStyle(fontSize: screenWidth * 0.038))),
                  Text("${item["price"].toString()} BHD",
                      style: TextStyle(fontSize: screenWidth * 0.038)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
