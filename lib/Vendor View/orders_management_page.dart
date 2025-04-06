import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order_details_page.dart';

const Color primaryRed = Color(0xFFBF0000);

class OrderManagementPage extends StatefulWidget {
  const OrderManagementPage({super.key});

  @override
  State<OrderManagementPage> createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends State<OrderManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _mainTabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  final List<String> historyStatuses = [
    "All",
    "In Progress",
    "Completed",
    "Rejected"
  ];
  String selectedHistoryStatus = "All";

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
  }

  Stream<QuerySnapshot> get requestsStream => _firestore
      .collection('order')
      .where('Accepted', isNull: true)
      .where('Vendor_ID', isEqualTo: _user?.uid)
      .snapshots();

  Stream<QuerySnapshot> get historyStream {
    Query query = _firestore
        .collection('order')
        .where('Accepted', isNull: false)
        .where('Vendor_ID', isEqualTo: _user?.uid)
        .orderBy('Order_Number', descending: true);

    if (selectedHistoryStatus != "All") {
      if (selectedHistoryStatus == "In Progress") {
        query = query.where('Status', whereIn: ['Preparing', 'On The Way']);
      } else if (selectedHistoryStatus == "Rejected") {
        query = query.where('Status', whereIn: ['Cancelled', 'Rejected']);
      } else {
        query = query.where('Status', whereIn: ['Delivered', 'Compeleted']);
      }
    }

    return query.snapshots();
  }

  Future<void> _updateOrderStatus(String orderId, bool accepted) async {
    await _firestore.collection('order').doc(orderId).update({
      'Accepted': accepted,
      'Status': accepted ? 'Preparing' : 'Rejected',
      'Order_Date': FieldValue.serverTimestamp(),
    });
  }

  void _showConfirmationDialog(String orderId, bool isAccept) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            vertical: screenHeight * 0.03,
            horizontal: screenWidth * 0.05,
          ),
          title: Text(
            isAccept ? 'Accept Order?' : 'Reject Order?',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: screenWidth * 0.06,
              fontWeight: FontWeight.bold,
              color: primaryRed,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: screenHeight * 0.01),
              Container(
                alignment: Alignment.center,
                child: Text(
                  isAccept
                      ? "Are you sure you want to accept this order?"
                      : "Are you sure you want to reject this order?",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: primaryRed),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(screenWidth * 0.02),
                        ),
                        padding:
                            EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _handleOrderAction(orderId, isAccept);
                      },
                      child: Text(
                        'Yes',
                        style: TextStyle(
                            color: primaryRed,
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.04),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryRed,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(screenWidth * 0.02),
                        ),
                        padding:
                            EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'No',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.04),
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

  Future<void> _handleOrderAction(String orderId, bool accepted) async {
    await _updateOrderStatus(orderId, accepted);

    _showStatusDialog(
      accepted ? "Order Accepted" : "Order Rejected",
      accepted ? Icons.check : Icons.close,
    );

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const OrderManagementPage()),
        (route) => false,
      );
    });
  }

  void _showStatusDialog(String title, IconData icon) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        return AlertDialog(
          backgroundColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.03, horizontal: screenWidth * 0.05),
          title: Container(
            padding: EdgeInsets.all(screenWidth * 0.05),
            decoration: const BoxDecoration(
              color: primaryRed,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: screenWidth * 0.12,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                alignment: Alignment.center,
                child: Text(
                  'Please wait. You will be redirected shortly.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.w300,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryRed),
              ),
            ],
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 3), () => Navigator.pop(context));
  }

  Widget _CustomerInfoWidget(String customerId) {
    final screenWidth = MediaQuery.of(context).size.width;
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('Customer').doc(customerId).get(),
      builder: (context, snapshot) {
        return CircleAvatar(
          radius: screenWidth * 0.06,
          backgroundImage: NetworkImage(
              (snapshot.data?.data() as Map<String, dynamic>?)?['Photo']
                          ?.isNotEmpty ??
                      false
                  ? (snapshot.data!.data() as Map<String, dynamic>)['Photo']
                  : 'https://i.imgur.com/OtAn7hT.jpeg'),
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return StreamBuilder<QuerySnapshot>(
      stream: requestsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data!.docs;

        return ListView.separated(
          padding: EdgeInsets.all(screenWidth * 0.04),
          itemCount: orders.length,
          separatorBuilder: (_, __) => SizedBox(height: screenHeight * 0.02),
          itemBuilder: (context, index) {
            final order = orders[index];
            final data = order.data() as Map<String, dynamic>;

            return Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03)),
              elevation: 1,
              child: InkWell(
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                onTap: () => _navigateToOrderDetails(context, order, false),
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (data['Customer_ID'] != null)
                            _CustomerInfoWidget(data['Customer_ID'] as String)
                          else
                            CircleAvatar(
                              radius: screenWidth * 0.06,
                              backgroundImage: const NetworkImage(
                                  'https://i.imgur.com/OtAn7hT.jpeg'),
                            ),
                          SizedBox(width: screenWidth * 0.03),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  data['Order_Number'] ?? '',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.03,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.01),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                        "${data['Total']?.toStringAsFixed(3)} BHD",
                                        style: TextStyle(
                                            fontSize: screenWidth * 0.035)),
                                    SizedBox(width: screenWidth * 0.02),
                                    const Text("|",
                                        style: TextStyle(color: Colors.grey)),
                                    SizedBox(width: screenWidth * 0.02),
                                    Text(
                                        "${(data['Items'] as List).length} Items",
                                        style: TextStyle(
                                            fontSize: screenWidth * 0.035)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  _showConfirmationDialog(order.id, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryRed,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        screenWidth * 0.02)),
                                padding: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.017),
                              ),
                              child: Text("Accept",
                                  style:
                                      TextStyle(fontSize: screenWidth * 0.04)),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  _showConfirmationDialog(order.id, false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryRed,
                                side: const BorderSide(color: primaryRed),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        screenWidth * 0.02)),
                                padding: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.017),
                              ),
                              child: Text("Reject",
                                  style:
                                      TextStyle(fontSize: screenWidth * 0.04)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return StreamBuilder<QuerySnapshot>(
      stream: historyStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            _buildStatusFilter(),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.all(screenWidth * 0.04),
                itemCount: snapshot.data!.docs.length,
                separatorBuilder: (_, __) =>
                    SizedBox(height: screenHeight * 0.02),
                itemBuilder: (context, index) {
                  final order = snapshot.data!.docs[index];
                  final data = order.data() as Map<String, dynamic>;

                  return Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(screenWidth * 0.03)),
                    elevation: 1,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      onTap: () =>
                          _navigateToOrderDetails(context, order, true),
                      child: Padding(
                        padding: EdgeInsets.all(screenWidth * 0.04),
                        child: Row(
                          children: [
                            if (data['Customer_ID'] != null)
                              _CustomerInfoWidget(data['Customer_ID'] as String)
                            else
                              CircleAvatar(
                                radius: screenWidth * 0.06,
                                backgroundImage: const NetworkImage(
                                    'https://i.imgur.com/OtAn7hT.jpeg'),
                              ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Order ${data['Order_Number'] ?? ''}",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: screenWidth * 0.04)),
                                  Text(
                                      "${data['Total']?.toStringAsFixed(3)} BHD",
                                      style: TextStyle(
                                          fontSize: screenWidth * 0.035)),
                                ],
                              ),
                            ),
                            _buildStatusPill(data['Status'] ?? 'Unknown'),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToOrderDetails(
      BuildContext context, QueryDocumentSnapshot order, bool isHistory) {
    final data = order.data() as Map<String, dynamic>;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailsPage(
          orderData: data,
          isHistory: isHistory,
          onAccept:
              isHistory ? null : () => _showConfirmationDialog(order.id, true),
          onReject:
              isHistory ? null : () => _showConfirmationDialog(order.id, false),
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      height: screenHeight * 0.05,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: historyStatuses.length,
        itemBuilder: (context, index) {
          final status = historyStatuses[index];
          final isSelected = status == selectedHistoryStatus;
          return GestureDetector(
            onTap: () => setState(() => selectedHistoryStatus = status),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
              padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.01),
              decoration: BoxDecoration(
                color: isSelected ? primaryRed : Colors.grey[200],
                borderRadius: BorderRadius.circular(screenWidth * 0.1),
              ),
              child: Text(
                status,
                style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.04),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final Color bgColor = Colors.grey[200]!;
    Color textColor = Colors.black;
    switch (status) {
      case 'Delivered':
        textColor = Colors.green;
        break;
      case 'Preparing':
      case 'On The Way':
        textColor = Colors.orange;
        break;
      case 'Rejected':
      case 'Cancelled':
        textColor = Colors.red;
        break;
    }
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.03, vertical: screenHeight * 0.005),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(screenWidth * 0.1),
      ),
      child: Text(
        status,
        style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.03),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
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
                color: Color(0xFFBF0000),
              ),
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.only(
                    top: screenHeight * 0.001, left: screenWidth * 0.02),
                child: Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: MediaQuery.of(context).size.width * 0.055,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'Orders',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: MediaQuery.of(context).size.width * 0.06,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _mainTabController,
          indicatorColor: primaryRed,
          labelColor: primaryRed,
          unselectedLabelColor: Colors.grey,
          labelStyle: TextStyle(
            fontSize: MediaQuery.of(context).size.height * 0.02,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: "Requests"),
            Tab(text: "History"),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: TabBarView(
          controller: _mainTabController,
          children: [_buildRequestsTab(), _buildHistoryTab()],
        ),
      ),
    );
  }
}
