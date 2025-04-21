import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hometouch/Customer%20View/bottom_nav_bar.dart';
import 'package:hometouch/Customer%20View/cart_page.dart';
import 'package:hometouch/Customer%20View/order_tracking_page.dart';
import 'package:hometouch/Common%20Pages/review_page.dart';
import 'package:intl/intl.dart';

const Color primaryRed = Color(0xFFBF0000);

Color getStatusBackground(String status) {
  switch (status.toLowerCase()) {
    case 'cancelled':
    case 'rejected':
      return Colors.red.shade100;
    case 'preparing':
      return Colors.yellow.shade100;
    case 'on the way':
    case 'ready for pickup':
      return Colors.yellow.shade100;
    case 'delivered':
    case 'picked up':
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
    case 'ready for pickup':
      return Colors.yellow.shade800;
    case 'delivered':
    case 'picked up':
      return Colors.green;
    default:
      return primaryRed;
  }
}

class OrdersPage extends StatefulWidget {
  final bool isFromNavBar;

  const OrdersPage({super.key, this.isFromNavBar = false});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> ongoingOrders = [];
  List<Map<String, dynamic>> historyOrders = [];
  bool isLoading = true;
  final int _selectedIndex = 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    try {
      QuerySnapshot orderSnapshot = await FirebaseFirestore.instance
          .collection('order')
          .where("Customer_ID", isEqualTo: user.uid)
          .orderBy("Order_Date", descending: true)
          .get();

      List<Map<String, dynamic>> ongoing = [];
      List<Map<String, dynamic>> history = [];

      for (var doc in orderSnapshot.docs) {
        var order = doc.data() as Map<String, dynamic>;

        if (order["Accepted"] == null) continue;

        order["orderId"] = doc.id;

        String vendorId = order["Vendor_ID"];
        DocumentSnapshot vendorSnapshot = await FirebaseFirestore.instance
            .collection('vendor')
            .doc(vendorId)
            .get();

        if (vendorSnapshot.exists) {
          order["vendorLogo"] = vendorSnapshot["Logo"];
          order["restaurant"] = vendorSnapshot["Name"];
        } else {
          order["vendorLogo"] = 'https://via.placeholder.com/50';
          order["restaurant"] = "Unknown Vendor";
        }

        String status = order["Status"].toString().toLowerCase();

        if (status == "preparing" ||
            status == "on the way" ||
            status == "ready for pickup") {
          ongoing.add(order);
        } else {
          history.add(order);
        }
      }

      setState(() {
        ongoingOrders = ongoing;
        historyOrders = history;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching orders: $e");
      setState(() => isLoading = false);
    }
  }

  void showCancelOrderDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
          title: const Text(
            'Cancel Order?',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFBF0000),
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                alignment: Alignment.center,
                child: const Text(
                  'Are you sure you want to cancel this order?',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFBF0000)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _cancelOrder(orderId);
                      },
                      child: const Text(
                        'Yes',
                        style: TextStyle(
                          color: Color(0xFFBF0000),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBF0000),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'No',
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

  Future<void> _cancelOrder(String orderId) async {
    try {
      final orderRef =
          FirebaseFirestore.instance.collection('order').doc(orderId);
      final orderSnapshot = await orderRef.get();
      if (!orderSnapshot.exists) return;

      final orderData = orderSnapshot.data() as Map<String, dynamic>;
      final total = orderData['Total'] as double;
      final totalVendorRevenue = orderData['Total_Vendor_Revenue'] as double;
      final vendorId = orderData['Vendor_ID'] as String;
      final customerId = orderData['Customer_ID'] as String;
      final orderDate = (orderData['Order_Date'] as Timestamp).toDate();
      final deliveryCost =
          double.parse(orderData['Deilvery_Cost'].toStringAsFixed(3));

      final vendorRef =
          FirebaseFirestore.instance.collection('vendor').doc(vendorId);
      await vendorRef.update({
        'Total_Orders': FieldValue.increment(-1),
        'Total_Revenue': FieldValue.increment(-totalVendorRevenue),
      });
      final monthYear = DateFormat('yyyy-MM').format(orderDate);
      await vendorRef.collection('Monthly_Sales').doc(monthYear).update({
        'Orders': FieldValue.increment(-1),
        'Sales': FieldValue.increment(-totalVendorRevenue),
      });
      final dayDate = DateFormat('yyyy-MM-dd').format(orderDate);
      await vendorRef.collection('Sales_Data').doc(dayDate).update({
        'Orders': FieldValue.increment(-1),
        'Sales': FieldValue.increment(-totalVendorRevenue),
      });

      final driverId = orderData['Driver_ID'] as String?;
      if (driverId != null && driverId != "Pending" && driverId.isNotEmpty) {
        final driverRef =
            FirebaseFirestore.instance.collection('Driver').doc(driverId);
        await driverRef.update({
          'Total_Orders': FieldValue.increment(-1),
          'Total_Revenue': FieldValue.increment(-deliveryCost),
          'isBusy': false,
        });
        await driverRef.collection('Sales_Data').doc(dayDate).set({
          'Orders': FieldValue.increment(-1),
          'Revenue': FieldValue.increment(-deliveryCost),
        }, SetOptions(merge: true));
      }

      final customerRef =
          FirebaseFirestore.instance.collection('Customer').doc(customerId);
      await customerRef.update({
        'Total_Orders': FieldValue.increment(-1),
        'Total_Expensive': FieldValue.increment(-total),
      });
      await customerRef.collection('Monthly_Expensive').doc(monthYear).set({
        'Orders': FieldValue.increment(-1),
        'Expensive': FieldValue.increment(-total),
      }, SetOptions(merge: true));

      if (orderData['Accepted'] == true) {
        await customerRef
            .update({'Loyalty_Points': FieldValue.increment(-100)});
      }

      await orderRef.update({'Status': 'Cancelled'});

      if (mounted) {
        _fetchOrders();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order cancelled successfully!")),
        );
      }
    } catch (e) {
      print("Error cancelling order: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
  }

  void _reorderItems(Map<String, dynamic> order) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final cartRef = FirebaseFirestore.instance
          .collection('Customer')
          .doc(user.uid)
          .collection('cart');

      var cartDocs = await cartRef.get();
      for (var doc in cartDocs.docs) {
        await doc.reference.delete();
      }

      for (var item in order['Items']) {
        await cartRef.add({
          "name": item["name"],
          "price": item["price"],
          "quantity": item["quantity"],
          "addOns": item["addOns"] ?? [],
          "image": item["image"] ?? "",
          "vendorId": order["Vendor_ID"],
        });
      }

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CartPage()),
      );
    } catch (e) {
      print("Error reordering items: $e");
    }
  }

  void _rateVendor(String vendorId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewPage(vendorId: vendorId),
      ),
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders, bool isOngoing) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: primaryRed),
      );
    }

    if (orders.isEmpty) {
      return const Center(child: Text("No orders available"));
    }

    return ListView.separated(
      padding: EdgeInsets.only(
          top: screenWidth * 0.04,
          left: screenWidth * 0.02,
          right: screenWidth * 0.02,
          bottom: screenWidth * 0.04),
      itemCount: orders.length,
      separatorBuilder: (context, index) =>
          SizedBox(height: screenHeight * 0.02),
      itemBuilder: (context, index) {
        final order = orders[index];

        Timestamp? orderTimestamp = order['Order_Date'];
        bool canCancel = false;

        if (orderTimestamp != null) {
          DateTime orderTime = orderTimestamp.toDate();
          Duration timeSinceOrder = DateTime.now().difference(orderTime);
          canCancel = timeSinceOrder.inMinutes < 3;
        }

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
          ),
          elevation: 4,
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.only(
                top: screenWidth * 0.04,
                left: screenWidth * 0.02,
                right: screenWidth * 0.02,
                bottom: screenWidth * 0.04),
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: order['vendorLogo'] != null
                        ? NetworkImage(order['vendorLogo'])
                        : const NetworkImage('https://via.placeholder.com/50'),
                    radius: screenWidth * 0.08,
                  ),
                  title: Text(
                    order['restaurant'] ?? 'N/A',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.045,
                    ),
                  ),
                  subtitle: Padding(
                    padding: EdgeInsets.only(top: screenHeight * 0.005),
                    child: Text(
                      "${order['Total'] ?? '0.000'} BHD | ${order['Items']?.length ?? 0} Items",
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
                        order['Order_Number'] ?? 'N/A',
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
                          color: getStatusBackground(order['Status'] ?? ''),
                          borderRadius:
                              BorderRadius.circular(screenWidth * 0.02),
                        ),
                        child: Text(
                          order['Status'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: screenWidth * 0.03,
                            color: getStatusTextColor(order['Status'] ?? ''),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isOngoing) ...[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderTrackingPage(
                                    orderId: order['orderId']),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryRed,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.015),
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
                          onPressed: canCancel
                              ? () => showCancelOrderDialog(
                                  context, order['orderId'])
                              : null,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor:
                                canCancel ? primaryRed : Colors.grey,
                            side: BorderSide(
                                color: canCancel ? primaryRed : Colors.grey,
                                width: screenWidth * 0.005),
                            padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.015),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(screenWidth * 0.02),
                            ),
                          ),
                          child: Text(
                            "Cancel",
                            style: TextStyle(fontSize: screenWidth * 0.04),
                          ),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _reorderItems(order),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryRed,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.015),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(screenWidth * 0.02),
                            ),
                          ),
                          child: Text(
                            "Re-order",
                            style: TextStyle(fontSize: screenWidth * 0.04),
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _rateVendor(order['Vendor_ID']),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: primaryRed,
                            side: BorderSide(
                                color: primaryRed, width: screenWidth * 0.005),
                            padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.015),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(screenWidth * 0.02),
                            ),
                          ),
                          child: Text(
                            "Rate",
                            style: TextStyle(fontSize: screenWidth * 0.04),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
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
          leading: widget.isFromNavBar
              ? const SizedBox()
              : Padding(
                  padding: EdgeInsets.only(
                      top: screenHeight * 0.025, left: screenWidth * 0.02),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFBF0000),
                      ),
                      alignment: Alignment.center,
                      child: Padding(
                        padding: EdgeInsets.only(
                            top: screenHeight * 0.001,
                            left: screenWidth * 0.02),
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: screenWidth * 0.055,
                        ),
                      ),
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
            _buildOrderList(ongoingOrders, true),
            _buildOrderList(historyOrders, false),
          ],
        ),
        bottomNavigationBar: BottomNavBar(selectedIndex: 3),
        floatingActionButton: SizedBox(
          height: 58,
          width: 58,
          child: FloatingActionButton(
            onPressed: () {
              if (_selectedIndex != 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CartPage(isFromNavBar: true)),
                );
              }
            },
            backgroundColor: const Color(0xFFBF0000),
            shape: const CircleBorder(),
            elevation: 5,
            child:
                const Icon(Icons.shopping_cart, color: Colors.white, size: 30),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}
