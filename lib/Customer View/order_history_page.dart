import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hometouch/Customer%20View/bottom_nav_bar.dart';
import 'package:hometouch/Customer%20View/cart_page.dart';
import 'package:hometouch/Customer%20View/order_tracking_page.dart';
import 'package:hometouch/Customer%20View/review_page.dart';

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
  int _selectedIndex = 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("❌ No user logged in");
      return;
    }

    try {
      print("🔍 Fetching orders for Customer_ID: ${user.uid}");

      QuerySnapshot orderSnapshot = await FirebaseFirestore.instance
          .collection('order')
          .where("Customer_ID", isEqualTo: user.uid)
          .orderBy("Order_Date", descending: true)
          .get();

      if (orderSnapshot.docs.isEmpty) {
        print("⚠️ No orders found for user: ${user.uid}");
      } else {
        print("✅ Found ${orderSnapshot.docs.length} orders");
      }

      List<Map<String, dynamic>> ongoing = [];
      List<Map<String, dynamic>> history = [];

      for (var doc in orderSnapshot.docs) {
        var order = doc.data() as Map<String, dynamic>;
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

        if (status == "preparing" || status == "on the way") {
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
      print("❌ Error fetching orders: $e");
      setState(() => isLoading = false);
    }
  }

  void _cancelOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('order')
          .doc(orderId)
          .update({"Status": "Cancelled"});

      _fetchOrders();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order cancelled successfully!")),
      );
    } catch (e) {
      print("❌ Error cancelling order: $e");
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

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CartPage()),
      );
    } catch (e) {
      print("❌ Error reordering items: $e");
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
      padding: EdgeInsets.all(screenWidth * 0.04),
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
            padding: EdgeInsets.all(screenWidth * 0.04),
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
                              ? () => _cancelOrder(order['orderId'])
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
                    top: screenHeight * 0.03,
                    left: screenWidth * 0.02,
                    right: screenWidth * 0.02,
                  ),
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
                      padding: EdgeInsets.all(screenHeight * 0.01),
                      child: Padding(
                        padding: EdgeInsets.only(left: screenWidth * 0.02),
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
        floatingActionButton: Container(
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
