import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hometouch/Driver View/driver_order_tracking_page.dart';

const Color primaryRed = Color(0xFFBF0000);

Color getStatusBackground(String status) {
  switch (status.toLowerCase()) {
    case 'cancelled':
    case 'rejected':
      return Colors.red.shade100;
    case 'preparing':
      return Colors.yellow.shade100;
    case 'on the way':
      return Colors.yellow.shade100;
    case 'delivered':
      return Colors.green.shade100;
    default:
      return Colors.grey.shade200;
  }
}

Color getStatusTextColor(String status) {
  switch (status.toLowerCase()) {
    case 'cancelled':
    case 'rejected':
      return Colors.red;
    case 'preparing':
      return Colors.yellow.shade800;
    case 'on the way':
      return Colors.yellow.shade800;
    case 'delivered':
      return Colors.green;
    default:
      return primaryRed;
  }
}

class DriverOrdersPage extends StatefulWidget {
  const DriverOrdersPage({Key? key}) : super(key: key);

  @override
  State<DriverOrdersPage> createState() => _DriverOrdersPageState();
}

class _DriverOrdersPageState extends State<DriverOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _driverId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final user = FirebaseAuth.instance.currentUser;
    _driverId = user?.uid ?? '';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> getOngoingOrders() {
    return FirebaseFirestore.instance
        .collection('order')
        .where('Driver_ID', isEqualTo: _driverId)
        .where('Status', whereIn: ['Preparing', 'On The Way']).snapshots();
  }

  Stream<QuerySnapshot> getHistoryOrders() {
    return FirebaseFirestore.instance
        .collection('order')
        .where('Driver_ID', isEqualTo: _driverId)
        .where('Status',
            whereIn: ['Delivered', 'Cancelled', 'Rejected']).snapshots();
  }

  void _trackOrder(String orderId) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => OrderTrackingPage(orderId: orderId)));
  }

  Future<void> _rejectOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('order').doc(orderId).update({
        "Driver_ID": "Pending",
      });

      QuerySnapshot pendingOrdersSnapshot = await FirebaseFirestore.instance
          .collection('order')
          .where("Driver_ID", isEqualTo: "Pending")
          .get();

      final List<DocumentSnapshot> pendingOrders =
          pendingOrdersSnapshot.docs.where((doc) => doc.id != orderId).toList();

      if (pendingOrders.isNotEmpty) {
        DocumentSnapshot nextOrder = pendingOrders.first;

        await FirebaseFirestore.instance
            .collection('order')
            .doc(nextOrder.id)
            .update({
          "Driver_ID": _driverId,
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
            .doc(_driverId)
            .update({"isBusy": false});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Order rejected successfully! No other pending orders available."),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error rejecting order: ${e.toString()}")),
      );
    }
  }

  Widget _buildOrderCard(DocumentSnapshot orderDoc, bool isOngoing,
      double screenWidth, double screenHeight) {
    final orderData = orderDoc.data() as Map<String, dynamic>;
    final orderNumber = orderData['Order_Number'] ?? 'N/A';
    final status = orderData['Status'] ?? 'N/A';
    final total = orderData['Total'] ?? '0.000';
    final items = orderData['Items'] as List<dynamic>? ?? [];

    Timestamp? timeStamp;
    if (orderData.containsKey("assignmentTimestamp") &&
        orderData["assignmentTimestamp"] != null) {
      timeStamp = orderData["assignmentTimestamp"] as Timestamp;
    } else {
      timeStamp = orderData["Order_Date"] as Timestamp?;
    }

    bool canReject = false;
    if (timeStamp != null) {
      final DateTime startTime = timeStamp.toDate();
      final Duration timeSinceAssigned = DateTime.now().difference(startTime);
      canReject = timeSinceAssigned.inMinutes < 3;
    }

    final vendorId = orderData['Vendor_ID'] as String?;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
      ),
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          children: [
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('vendor')
                  .doc(vendorId)
                  .get(),
              builder: (context, snapshot) {
                String restaurant = 'Unknown';
                String vendorLogo = 'https://via.placeholder.com/50';

                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData &&
                    snapshot.data != null &&
                    snapshot.data!.exists) {
                  final vendorData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  restaurant = vendorData['Name'] ?? 'Unknown';
                  vendorLogo =
                      vendorData['Logo'] ?? 'https://via.placeholder.com/50';
                }

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(vendorLogo),
                    radius: screenWidth * 0.08,
                  ),
                  title: Text(
                    restaurant,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.045,
                    ),
                  ),
                  subtitle: Padding(
                    padding: EdgeInsets.only(top: screenHeight * 0.005),
                    child: Text(
                      "$total BHD | ${items.length} Items",
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        orderNumber,
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          color: Colors.grey[500],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: screenHeight * 0.005,
                        ),
                        decoration: BoxDecoration(
                          color: getStatusBackground(status),
                          borderRadius:
                              BorderRadius.circular(screenWidth * 0.02),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: screenWidth * 0.03,
                            color: getStatusTextColor(status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (isOngoing)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _trackOrder(orderDoc.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryRed,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.015,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(screenWidth * 0.02),
                        ),
                      ),
                      child: Text(
                        "Track Order",
                        style: TextStyle(fontSize: screenWidth * 0.04),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          canReject ? () => _rejectOrder(orderDoc.id) : null,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: canReject ? primaryRed : Colors.grey,
                        side: BorderSide(
                          color: canReject ? primaryRed : Colors.grey,
                          width: screenWidth * 0.005,
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.015,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(screenWidth * 0.02),
                        ),
                      ),
                      child: Text(
                        "Reject",
                        style: TextStyle(fontSize: screenWidth * 0.04),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab({
    required BuildContext context,
    required Stream<QuerySnapshot> ordersStream,
    required bool isOngoing,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return StreamBuilder<QuerySnapshot>(
      stream: ordersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: primaryRed));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No orders available'));
        }

        final docs = snapshot.data!.docs;

        return ListView.separated(
          padding: EdgeInsets.all(screenWidth * 0.04),
          itemCount: docs.length,
          separatorBuilder: (context, index) =>
              SizedBox(height: screenHeight * 0.02),
          itemBuilder: (context, index) {
            return _buildOrderCard(
                docs[index], isOngoing, screenWidth, screenHeight);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: Padding(
            padding: EdgeInsets.only(
                top: screenHeight * 0.025, left: screenWidth * 0.02),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryRed,
                ),
                alignment: Alignment.center,
                padding: EdgeInsets.only(
                    top: screenHeight * 0.001, left: screenWidth * 0.02),
                child: Icon(Icons.arrow_back_ios,
                    color: Colors.white, size: screenWidth * 0.055),
              ),
            ),
          ),
          title: Padding(
            padding: EdgeInsets.only(top: screenHeight * 0.02),
            child: Text(
              'Orders',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: screenWidth * 0.06,
              ),
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: primaryRed,
            labelColor: primaryRed,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontSize: screenHeight * 0.02),
            tabs: const [
              Tab(text: "Ongoing"),
              Tab(text: "History"),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOrdersTab(
                context: context,
                ordersStream: getOngoingOrders(),
                isOngoing: true),
            _buildOrdersTab(
                context: context,
                ordersStream: getHistoryOrders(),
                isOngoing: false),
          ],
        ),
      ),
    );
  }
}
