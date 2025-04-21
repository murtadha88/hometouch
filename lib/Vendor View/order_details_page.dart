import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hometouch/Common%20Pages/chat_page.dart';
import 'package:url_launcher/url_launcher.dart';

const Color primaryRed = Color(0xFFBF0000);

class OrderDetailsPage extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final bool isHistory;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const OrderDetailsPage({
    super.key,
    required this.orderData,
    this.isHistory = false,
    this.onAccept,
    this.onReject,
  });

  @override
  _OrderDetailsPageState createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late Map<String, dynamic> orderData;

  @override
  void initState() {
    super.initState();
    orderData = Map<String, dynamic>.from(widget.orderData);
  }

  Future<void> _openGoogleMaps(GeoPoint location) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      debugPrint("Could not open Google Maps");
    }
  }

  Future<void> _handleChatWithCustomer(
      BuildContext context, String? customerId) async {
    if (customerId == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String vendorId = user.uid;

    QuerySnapshot chatQuery = await FirebaseFirestore.instance
        .collection("chat")
        .where("participants", arrayContains: vendorId)
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
            chatId: existingChatId!,
            currentUserId: vendorId,
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
        "User1": vendorId,
        "User2": customerId,
        "participants": [vendorId, customerId],
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            chatId: newChatRef.id,
            currentUserId: vendorId,
          ),
        ),
      );
    }
  }

  Future<void> _handleChatWithDriver(
      BuildContext context, String? driverId) async {
    if (driverId == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String vendorId = user.uid;

    QuerySnapshot chatQuery = await FirebaseFirestore.instance
        .collection("chat")
        .where("participants", arrayContains: vendorId)
        .get();

    String? existingChatId;

    for (var doc in chatQuery.docs) {
      List<dynamic> participants = doc["participants"];
      if (participants.contains(driverId)) {
        existingChatId = doc.id;
        break;
      }
    }

    if (existingChatId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            chatId: existingChatId!,
            currentUserId: vendorId,
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
        "User1": vendorId,
        "User2": driverId,
        "participants": [vendorId, driverId],
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            chatId: newChatRef.id,
            currentUserId: vendorId,
          ),
        ),
      );
    }
  }

  void _handleCall(BuildContext context, String? phoneNumber) async {
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(callUri)) {
        await launchUrl(callUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch phone dialer'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not available'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final items = List<Map<String, dynamic>>.from(orderData['Items'] ?? []);

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
                  color: primaryRed,
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
              'Order Details',
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
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('Customer')
                  .doc(orderData['Customer_ID'] as String?)
                  .get(),
              builder: (context, snapshot) {
                String name = 'No Name';
                String imageUrl = 'https://i.imgur.com/OtAn7hT.jpeg';

                if (snapshot.hasData && snapshot.data!.exists) {
                  final customerData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  name = customerData['Name'] ?? name;
                  imageUrl = customerData['Photo'] ?? imageUrl;
                }

                final address = orderData['Customer_Address'] ?? {};
                final block = address['Block'] ?? '';
                final building = address['Building'] ?? '';
                final road = address['Road'] ?? '';
                final apartment = address['Apartment'];
                final floor = address['Floor'];
                final office = address['Office'];
                final companyName = address['Company_Name'];
                final location = address['Location'] ?? '';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer Information:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.05,
                        color: primaryRed,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: screenWidth * 0.07,
                          backgroundImage: NetworkImage(imageUrl),
                        ),
                        SizedBox(width: screenWidth * 0.04),
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: CircleAvatar(
                            backgroundColor: primaryRed,
                            radius: screenWidth * 0.06,
                            child: Icon(Icons.chat,
                                color: Colors.white, size: screenWidth * 0.05),
                          ),
                          onPressed: () => _handleChatWithCustomer(
                              context, orderData['Customer_ID']?.toString()),
                        ),
                        IconButton(
                          icon: CircleAvatar(
                            backgroundColor: primaryRed,
                            radius: screenWidth * 0.06,
                            child: Icon(Icons.call,
                                color: Colors.white, size: screenWidth * 0.05),
                          ),
                          onPressed: () =>
                              _handleCall(context, orderData['Customer_Phone']),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      'Address Details:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.04),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      'Block: $block, Building: $building, Road: $road',
                      style: TextStyle(fontSize: screenWidth * 0.035),
                    ),
                    if (apartment != null)
                      Text('Apartment: $apartment',
                          style: TextStyle(fontSize: screenWidth * 0.035)),
                    if (floor != null)
                      Text('Floor: $floor',
                          style: TextStyle(fontSize: screenWidth * 0.035)),
                    if (office != null)
                      Text('Office: $office',
                          style: TextStyle(fontSize: screenWidth * 0.035)),
                    if (companyName != null)
                      Text('Company Name: $companyName',
                          style: TextStyle(fontSize: screenWidth * 0.035)),
                    if (location != null && location is GeoPoint)
                      Padding(
                        padding: EdgeInsets.only(top: screenHeight * 0.02),
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.map,
                              color: primaryRed, size: screenWidth * 0.05),
                          label: Text(
                            'View in Map',
                            style: TextStyle(
                                color: primaryRed,
                                fontSize: screenWidth * 0.04),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: primaryRed),
                            padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.015,
                                horizontal: screenWidth * 0.04),
                          ),
                          onPressed: () => _openGoogleMaps(location),
                        ),
                      ),
                  ],
                );
              },
            ),
            Divider(thickness: screenHeight * 0.001),
            Text(
              'Order Details:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.05,
                color: primaryRed,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Container(
              padding: EdgeInsets.all(screenWidth * 0.02),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _orderDetailItem(
                      "Order Number", orderData['Order_Number'], screenWidth),
                  _orderDetailItem(
                      "Delivery Type", orderData['Delivery_Type'], screenWidth),
                  _orderDetailItem(
                      "Order Date",
                      (orderData['Order_Date'] as Timestamp?)
                              ?.toDate()
                              .toString()
                              .substring(0, 16) ??
                          'N/A',
                      screenWidth),
                  _orderDetailItem("Payment Method",
                      orderData['Payment_Method'], screenWidth),
                  if (orderData['Schedule_Time'] != null)
                    _orderDetailItem(
                        "Schedule Time",
                        (orderData['Schedule_Time'] as Timestamp?)
                                ?.toDate()
                                .toString()
                                .substring(0, 16) ??
                            'N/A',
                        screenWidth),
                  _orderDetailItem("Status", orderData['Status'], screenWidth),
                  if (orderData['Accepted'] == true)
                    Column(
                      children: [
                        if (orderData['Delivery_Type'] == "Pickup")
                          if (orderData['Status'] == "Preparing")
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.02),
                              child: Center(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('order')
                                        .doc(orderData['Order_Number'])
                                        .update({'Status': 'Ready For Pickup'});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Order status updated to Ready For Pickup')),
                                    );
                                    setState(() {
                                      orderData['Status'] = 'Ready For Pickup';
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryRed,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.08,
                                      vertical: screenHeight * 0.015,
                                    ),
                                  ),
                                  child: Text(
                                    'Mark as Ready For Pickup',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else if (orderData['Status'] == "Ready For Pickup")
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.02),
                              child: Center(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('order')
                                        .doc(orderData['Order_Number'])
                                        .update({'Status': 'Picked Up'});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Order status updated to Picked Up')),
                                    );
                                    setState(() {
                                      orderData['Status'] = 'Picked Up';
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryRed,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.08,
                                      vertical: screenHeight * 0.015,
                                    ),
                                  ),
                                  child: Text(
                                    'Customer Picked Up the order',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            Container(),
                        if (orderData['Delivery_Type'] != "Pickup")
                          if (orderData['Status'] == "Preparing")
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.02),
                              child: Center(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('order')
                                        .doc(orderData['Order_Number'])
                                        .update({'Status': 'On The Way'});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Order status updated to On The Way')),
                                    );
                                    setState(() {
                                      orderData['Status'] = 'On The Way';
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryRed,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.08,
                                      vertical: screenHeight * 0.015,
                                    ),
                                  ),
                                  child: Text(
                                    'Mark as On The Way',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        if (orderData['Delivery_Type'] != "Pickup" &&
                            orderData['Status'] == "Preparing")
                          Padding(
                            padding:
                                EdgeInsets.only(bottom: screenHeight * 0.015),
                            child: Text(
                              "Click this button once the driver has picked up the order.",
                              style: TextStyle(
                                fontSize: screenWidth * 0.032,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            Divider(thickness: screenHeight * 0.001),
            Text(
              'Order Items:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.05,
                color: primaryRed,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            ...items.map((item) {
              final int quantity = item['quantity'] ?? 1;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: (item['image'] != null && item['image'].isNotEmpty)
                    ? Image.network(item['image'],
                        width: screenWidth * 0.15, height: screenWidth * 0.15)
                    : Icon(Icons.fastfood, size: screenWidth * 0.08),
                title: Text(
                  '${item['name'] ?? 'No Name'}${quantity > 1 ? ' (x$quantity)' : ''}',
                  style: TextStyle(fontSize: screenWidth * 0.04),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${(item['price'] as num?)?.toStringAsFixed(3) ?? '0.000'} BHD",
                      style: TextStyle(fontSize: screenWidth * 0.035),
                    ),
                    if (item['addOns'] != null)
                      ...(item['addOns'] as List).map<Widget>((addOn) => Text(
                            "+ ${addOn['name']} (${(addOn['price'] as num).toStringAsFixed(3)} BHD",
                            style: TextStyle(
                                fontSize: screenWidth * 0.03,
                                color: Colors.grey),
                          )),
                  ],
                ),
              );
            }),
            Divider(thickness: screenHeight * 0.001),
            Text(
              'Payment Summary:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.05,
                color: primaryRed,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            _buildDetailRow("Subtotal", orderData['Subtotal'], screenWidth),
            _buildDetailRow(
                "Delivery Cost", orderData['Delivery_Cost'], screenWidth),
            _buildDetailRow("Tax", orderData['Tax'], screenWidth),
            if ((orderData['Total_Points_Used'] ?? 0) > 0)
              Padding(
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Points Used',
                      style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                          color: primaryRed),
                    ),
                    Text(
                      '${orderData['Total_Points_Used']} Points',
                      style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                          color: primaryRed),
                    ),
                  ],
                ),
              ),
            _buildDetailRow("Total", orderData['Total'], screenWidth,
                isTotal: true),
            if (widget.isHistory && orderData['Driver_ID'] != null)
              Column(
                children: [
                  Divider(thickness: screenHeight * 0.001),
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('Driver')
                        .doc(orderData['Driver_ID'])
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Text(
                          'Driver details not available',
                          style: TextStyle(color: Colors.grey),
                        );
                      }

                      final driverData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final driverName = driverData['Name'] ?? 'Unknown Driver';
                      final driverPhone =
                          driverData['Phone'] ?? 'No phone available';
                      final driverImage = driverData['Photo'] ??
                          'https://i.imgur.com/OtAn7hT.jpeg';

                      return Row(
                        children: [
                          CircleAvatar(
                            radius: screenWidth * 0.07,
                            backgroundImage: NetworkImage(driverImage),
                          ),
                          SizedBox(width: screenWidth * 0.04),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(driverName,
                                    style: TextStyle(
                                        fontSize: screenWidth * 0.04,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: screenHeight * 0.005),
                                Text(
                                  'Phone: $driverPhone',
                                  style:
                                      TextStyle(fontSize: screenWidth * 0.035),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: CircleAvatar(
                              backgroundColor: primaryRed,
                              radius: screenWidth * 0.06,
                              child: Icon(Icons.chat,
                                  color: Colors.white,
                                  size: screenWidth * 0.05),
                            ),
                            onPressed: () => _handleChatWithDriver(
                                context, orderData['Driver_ID']?.toString()),
                          ),
                          IconButton(
                            icon: CircleAvatar(
                              backgroundColor: primaryRed,
                              radius: screenWidth * 0.06,
                              child: Icon(Icons.call,
                                  color: Colors.white,
                                  size: screenWidth * 0.05),
                            ),
                            onPressed: () => _handleCall(context, driverPhone),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              )
          ],
        ),
      ),
    );
  }

  Widget _orderDetailItem(String label, dynamic value, double screenWidth) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth * 0.02),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.black),
          children: [
            TextSpan(
              text: "$label: ",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value?.toString() ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value, double screenWidth,
      {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text("${(value ?? 0).toStringAsFixed(3)} BHD",
              style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
