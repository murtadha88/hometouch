import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'
    hide LocationAccuracy, AndroidSettings;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hometouch/Common%20Pages/chat_page.dart';
import 'package:hometouch/Driver%20View/driver_orders_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;

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
  Map<String, dynamic>? vendorData;
  Map<String, dynamic>? customerData;
  bool isLoading = true;
  final Set<Marker> _markers = {};

  String driverName = "Loading...";
  String driverPhone = "Loading...";
  String driverPhoto = "";
  LatLng? driverLocation;

  String vendorName = "Loading...";
  String vendorPhone = "Loading...";
  String vendorPhoto = "";
  LatLng? vendorLocation;

  String customerName = "Loading...";
  String customerPhone = "Loading...";
  String customerPhoto = "";
  LatLng? customerLocation;

  StreamSubscription<DocumentSnapshot>? _driverLocationSubscription;
  Timer? _refreshTimer;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
    _initBackgroundGeolocation();
    _startDriverLocationTracking();

    _refreshTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (mounted) _fetchOrderDetails();
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _refreshTimer?.cancel();
    _driverLocationSubscription?.cancel();
    bg.BackgroundGeolocation.removeListeners();
    super.dispose();
  }

  void _initBackgroundGeolocation() {
    bg.BackgroundGeolocation.onLocation((bg.Location location) async {
      print('[Background] Location: ${location.coords}');
      final driverId = FirebaseAuth.instance.currentUser?.uid;
      if (driverId != null) {
        await FirebaseFirestore.instance
            .collection("Driver")
            .doc(driverId)
            .update({
          "Location":
              GeoPoint(location.coords.latitude, location.coords.longitude),
        });
      }
      if (mounted) {
        setState(() {
          driverLocation =
              LatLng(location.coords.latitude, location.coords.longitude);
          _updateDriverMarker(driverLocation!);
        });
      }
    });

    bg.BackgroundGeolocation.onMotionChange((bg.Location location) {
      print('[Motion Change] location: ${location.coords}');
    });

    bg.BackgroundGeolocation.ready(
      bg.Config(
        desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
        distanceFilter: 10.0,
        stopOnTerminate: false,
        startOnBoot: true,
        debug: false,
        logLevel: bg.Config.LOG_LEVEL_VERBOSE,
        notification: bg.Notification(
          title: "Tracking Driver",
          text: "Background location tracking is active",
          channelName: "Driver Location",
        ),
      ),
    ).then((bg.State state) {
      print("[ready] BackgroundGeolocation ready: enabled=${state.enabled}");
      if (!state.enabled) {
        bg.BackgroundGeolocation.start();
      }
    });
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

      if (orderData?["Vendor_ID"] != null) {
        _fetchVendorDetails(orderData!["Vendor_ID"]);
      }
      if (orderData?["Customer_ID"] != null) {
        _fetchCustomerDetails(orderData!["Customer_ID"]);
      }
      if (orderData?["Customer_Address"] != null) {
        final address = orderData!["Customer_Address"];
        if (address["Location"] is GeoPoint) {
          GeoPoint geoPoint = address["Location"];
          customerLocation = LatLng(geoPoint.latitude, geoPoint.longitude);
          _updateCustomerMarker(customerLocation!);
        }
      }
    } catch (e) {
      print("Error fetching order: $e");
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
          Map<String, dynamic> data =
              driverSnapshot.data() as Map<String, dynamic>;
          setState(() {
            driverData = data;
            driverName = data["Name"] ?? "Unknown";
            driverPhone = data["Phone"]?.toString() ?? "No phone";
            driverPhoto = data["Photo"] ??
                "https://randomuser.me/api/portraits/men/1.jpg";
            if (data["Location"] is GeoPoint) {
              GeoPoint location = data["Location"];
              driverLocation = LatLng(location.latitude, location.longitude);
              _updateDriverMarker(driverLocation!);
            }
          });
        }
      });
    } catch (e) {
      print("Error fetching driver details: $e");
    }
  }

  Future<void> _fetchVendorDetails(String vendorId) async {
    try {
      DocumentSnapshot vendorSnapshot = await FirebaseFirestore.instance
          .collection("vendor")
          .doc(vendorId)
          .get();
      if (vendorSnapshot.exists && vendorSnapshot.data() != null) {
        Map<String, dynamic> data =
            vendorSnapshot.data() as Map<String, dynamic>;
        setState(() {
          vendorData = data;
          vendorName = data["Name"] ?? "Unknown Vendor";
          vendorPhone = data["Phone"]?.toString() ?? "No phone";
          vendorPhoto = data["Logo"] ?? "https://via.placeholder.com/50";
          if (data["Location"] is GeoPoint) {
            GeoPoint loc = data["Location"];
            vendorLocation = LatLng(loc.latitude, loc.longitude);
            _updateVendorMarker(vendorLocation!);
          }
        });
      }
    } catch (e) {
      print("Error fetching vendor details: $e");
    }
  }

  Future<void> _fetchCustomerDetails(String customerId) async {
    try {
      DocumentSnapshot customerSnapshot = await FirebaseFirestore.instance
          .collection("Customer")
          .doc(customerId)
          .get();
      if (customerSnapshot.exists && customerSnapshot.data() != null) {
        Map<String, dynamic> data =
            customerSnapshot.data() as Map<String, dynamic>;
        setState(() {
          customerData = data;
          customerName = data["Name"] ?? "Unknown Customer";
          customerPhone = data["Phone"]?.toString() ?? "No phone";
          customerPhoto = data["Photo"] ?? "https://via.placeholder.com/50";
        });
      }
    } catch (e) {
      print("Error fetching customer details: $e");
    }
  }

  void _startDriverLocationTracking() {
    if (orderData != null &&
        orderData?["Driver_ID"] != null &&
        orderData?["Driver_ID"] != "Pending") {
      _fetchDriverDetails(orderData!["Driver_ID"]);
    } else {
      _fetchDriverDetails(FirebaseAuth.instance.currentUser!.uid);
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    String driverId = user.uid;
    _locationTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      try {
        Position position = await Geolocator.getCurrentPosition();
        LatLng newLocation = LatLng(position.latitude, position.longitude);
        await FirebaseFirestore.instance
            .collection("Driver")
            .doc(driverId)
            .update({
          "Location": GeoPoint(newLocation.latitude, newLocation.longitude)
        });
        setState(() {
          driverLocation = newLocation;
        });
        _updateDriverMarker(newLocation);
      } catch (e) {
        print("Error in foreground tracking: $e");
      }
    });
  }

  Future<BitmapDescriptor> _getDriverMarkerIcon() async {
    return await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(100, 100)),
      'assets/car_pin.png',
    );
  }

  Future<void> _updateDriverMarker(LatLng location) async {
    final BitmapDescriptor customDriverMarker = await _getDriverMarkerIcon();
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == "driver");
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
      const ImageConfiguration(size: Size(100, 100)),
      'assets/customer_pin.png',
    );
  }

  void _updateCustomerMarker(LatLng location) async {
    final BitmapDescriptor customCustomerMarker =
        await _getCustomerMarkerIcon();
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == "customer");
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

  Future<BitmapDescriptor> _getVendorMarkerIcon() async {
    return await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(100, 100)),
      'assets/vendor_pin.png',
    );
  }

  void _updateVendorMarker(LatLng location) async {
    final BitmapDescriptor customVendorMarker = await _getVendorMarkerIcon();
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == "vendor");
      _markers.add(
        Marker(
          markerId: const MarkerId("vendor"),
          position: location,
          icon: customVendorMarker,
          infoWindow: const InfoWindow(title: "Vendor Location"),
        ),
      );
    });
  }

  Future<void> _handleShowLocation(LatLng location) async {
    final String url =
        'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Could not launch maps")));
    }
  }

  Future<void> _handleChatWithVendor() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || vendorData == null) return;

    String driverId = user.uid;
    String vendorId = orderData?["Vendor_ID"] ?? "";
    if (vendorId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Vendor not available.")));
      return;
    }

    QuerySnapshot chatQuery = await FirebaseFirestore.instance
        .collection("chat")
        .where("participants", arrayContains: driverId)
        .get();

    String? existingChatId;
    for (var doc in chatQuery.docs) {
      List<dynamic> participants = doc["participants"];
      if (participants.contains(vendorId)) {
        existingChatId = doc.id;
        break;
      }
    }

    if (existingChatId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            chatId: existingChatId ?? "",
            currentUserId: driverId,
          ),
        ),
      );
    } else {
      DocumentReference newChatRef =
          FirebaseFirestore.instance.collection("chat").doc();
      await newChatRef.set({
        "Last_Message": "",
        "Last_Message_Time": FieldValue.serverTimestamp(),
        "Seen": false,
        "Unread_Count": 0,
        "User1": driverId,
        "User2": vendorId,
        "participants": [driverId, vendorId],
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            chatId: newChatRef.id,
            currentUserId: driverId,
          ),
        ),
      );
    }
  }

  Future<void> _handleChatWithCustomer() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || customerData == null) return;

    String driverId = user.uid;
    String customerId = orderData?["Customer_ID"] ?? "";
    if (customerId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Customer not available.")));
      return;
    }

    QuerySnapshot chatQuery = await FirebaseFirestore.instance
        .collection("chat")
        .where("participants", arrayContains: driverId)
        .get();

    String? existingChatId;
    for (var doc in chatQuery.docs) {
      List<dynamic> participants = doc["participants"];
      if (participants.contains(customerId)) {
        existingChatId = doc.id;
        break;
      }
    }

    if (existingChatId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            chatId: existingChatId ?? "",
            currentUserId: driverId,
          ),
        ),
      );
    } else {
      DocumentReference newChatRef =
          FirebaseFirestore.instance.collection("chat").doc();
      await newChatRef.set({
        "Last_Message": "",
        "Last_Message_Time": FieldValue.serverTimestamp(),
        "Seen": false,
        "Unread_Count": 0,
        "User1": driverId,
        "User2": customerId,
        "participants": [driverId, customerId],
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            chatId: newChatRef.id,
            currentUserId: driverId,
          ),
        ),
      );
    }
  }

  Future<void> _handleCall(String phone) async {
    if (phone.isNotEmpty) {
      final Uri callUri = Uri(scheme: 'tel', path: phone);
      if (await canLaunchUrl(callUri)) {
        await launchUrl(callUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Could not launch phone dialer")));
      }
    }
  }

  void _showDeliveredConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
          title: Text(
            'Confirm Delivery',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryRed,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure you want to mark this order as delivered?',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: primaryRed),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },
                      child: Text(
                        'No',
                        style: TextStyle(
                          color: primaryRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => DriverOrdersPage()),
                        );
                        await _handleDeliveredOrder();
                      },
                      child: const Text(
                        'Yes',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleDeliveredOrder() async {
    try {
      await FirebaseFirestore.instance
          .collection('order')
          .doc(widget.orderId)
          .update({
        "Status": "Delivered",
      });

      final String driverId = FirebaseAuth.instance.currentUser!.uid;

      QuerySnapshot pendingOrdersSnapshot = await FirebaseFirestore.instance
          .collection('order')
          .where("Driver_ID", isEqualTo: "Pending")
          .get();

      final List<DocumentSnapshot> pendingOrders = pendingOrdersSnapshot.docs
          .where((doc) => doc.id != widget.orderId)
          .toList();

      if (pendingOrders.isNotEmpty) {
        DocumentSnapshot nextOrder = pendingOrders.first;
        await FirebaseFirestore.instance
            .collection('order')
            .doc(nextOrder.id)
            .update({
          "Driver_ID": driverId,
          "assignmentTimestamp": FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Another pending order has been assigned to you. You have 3 minutes to decide.",
            ),
          ),
        );
      } else {
        await FirebaseFirestore.instance
            .collection('Driver')
            .doc(driverId)
            .update({"isBusy": false});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Order delivered successfully! No other pending orders available.",
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error delivering order: ${e.toString()}")),
      );
    }
  }

  Widget _buildContactInfo(double screenWidth, double screenHeight) {
    final double buttonRadius = screenWidth * 0.05;
    final double iconSize = screenWidth * 0.05;
    return Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(vendorPhoto),
              radius: screenWidth * 0.066,
            ),
            SizedBox(width: screenWidth * 0.033),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendorName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.044,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.007),
                  Text(
                    "Phone: $vendorPhone",
                    style: TextStyle(
                      fontSize: screenWidth * 0.038,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: CircleAvatar(
                backgroundColor: primaryRed,
                radius: buttonRadius,
                child: Icon(
                  Icons.chat,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
              onPressed: _handleChatWithVendor,
            ),
            IconButton(
              icon: CircleAvatar(
                backgroundColor: primaryRed,
                radius: buttonRadius,
                child: Icon(
                  Icons.call,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
              onPressed: () => _handleCall(vendorPhone),
            ),
            if (vendorLocation != null)
              IconButton(
                icon: CircleAvatar(
                  backgroundColor: primaryRed,
                  radius: buttonRadius,
                  child: Icon(
                    Icons.location_on,
                    color: Colors.white,
                    size: iconSize,
                  ),
                ),
                onPressed: () => _handleShowLocation(vendorLocation!),
              ),
          ],
        ),
        Divider(
          height: screenHeight * 0.02,
          thickness: screenHeight * 0.002,
        ),
        Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(customerPhoto),
              radius: screenWidth * 0.066,
            ),
            SizedBox(width: screenWidth * 0.033),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customerName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.044,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.007),
                  Text(
                    "Phone: $customerPhone",
                    style: TextStyle(
                      fontSize: screenWidth * 0.038,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: CircleAvatar(
                backgroundColor: primaryRed,
                radius: buttonRadius,
                child: Icon(
                  Icons.chat,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
              onPressed: _handleChatWithCustomer,
            ),
            IconButton(
              icon: CircleAvatar(
                backgroundColor: primaryRed,
                radius: buttonRadius,
                child: Icon(
                  Icons.call,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
              onPressed: () => _handleCall(customerPhone),
            ),
            if (customerLocation != null)
              IconButton(
                icon: CircleAvatar(
                  backgroundColor: primaryRed,
                  radius: buttonRadius,
                  child: Icon(
                    Icons.location_on,
                    color: Colors.white,
                    size: iconSize,
                  ),
                ),
                onPressed: () => _handleShowLocation(customerLocation!),
              ),
          ],
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
      child: Row(children: rowChildren),
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
    List items = orderData?["Items"] as List? ?? [];
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
        ...List.generate(items.length, (index) {
          var item = items[index];
          return Padding(
            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.005),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: Text(item["name"],
                        style: TextStyle(fontSize: screenWidth * 0.038))),
                Text("${item["price"].toString()} BHD x${item['quantity']}",
                    style: TextStyle(fontSize: screenWidth * 0.038)),
              ],
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
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
                              vendorLocation ??
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
                      padding: EdgeInsets.all(screenWidth * 0.06),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryRed,
                          ),
                          padding: EdgeInsets.only(
                            left: screenWidth * 0.04,
                            top: screenWidth * 0.02,
                            right: screenWidth * 0.02,
                            bottom: screenWidth * 0.02,
                          ),
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
                  initialChildSize: 0.5,
                  minChildSize: 0.5,
                  maxChildSize: 0.8,
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
                            _buildContactInfo(screenWidth, screenHeight),
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
                            if (orderData?["Total_Points_Used"] != null &&
                                orderData?["Total_Points_Used"] > 0)
                              Padding(
                                padding: EdgeInsets.only(
                                    bottom: screenHeight * 0.01),
                                child: Text(
                                  "Points Used: ${orderData?["Total_Points_Used"]} Points",
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.bold,
                                    color: primaryRed,
                                  ),
                                ),
                              ),
                            Text(
                              "Total: ${orderData?["Total"].toString()} BHD",
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryRed,
                                foregroundColor: Colors.white,
                                minimumSize: Size(double.infinity, 50),
                              ),
                              onPressed: _showDeliveredConfirmationDialog,
                              child: Text(
                                "Delivered",
                                style: TextStyle(
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.bold,
                                ),
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
}
