import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order_details_page.dart';

const Color primaryRed = Color(0xFFBF0000);

class OrderManagementPage extends StatefulWidget {
  const OrderManagementPage({Key? key}) : super(key: key);

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
        .where('Vendor_ID', isEqualTo: _user?.uid);

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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
          title: Text(
            isAccept ? 'Accept Order?' : 'Reject Order?',
            style: const TextStyle(
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
              const SizedBox(height: 10),
              Container(
                alignment: Alignment.center,
                child: Text(
                  isAccept
                      ? "Are you sure you want to accept this order?"
                      : "Are you sure you want to reject this order?",
                  style: const TextStyle(
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
                        side: const BorderSide(color: primaryRed),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _handleOrderAction(orderId, isAccept);
                      },
                      child: const Text(
                        'Yes',
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
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('Customer').doc(customerId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage('https://i.imgur.com/OtAn7hT.jpeg'),
          );
        }

        final customerData = snapshot.data?.data() as Map<String, dynamic>?;
        final imageUrl = (customerData?['Photo']?.isNotEmpty ?? false)
            ? customerData!['Photo']
            : 'https://i.imgur.com/OtAn7hT.jpeg';

        return CircleAvatar(
          radius: 24,
          backgroundImage: NetworkImage(imageUrl),
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: requestsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data!.docs;

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final order = orders[index];
            final data = order.data() as Map<String, dynamic>;

            return Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 1,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _navigateToOrderDetails(context, order, false),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (data['Customer_ID'] != null)
                            _CustomerInfoWidget(data['Customer_ID'] as String)
                          else
                            const CircleAvatar(
                              radius: 24,
                              backgroundImage: NetworkImage(
                                  'https://i.imgur.com/OtAn7hT.jpeg'),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  data['Order_Number'] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                        "${data['Total']?.toStringAsFixed(3)} BHD"),
                                    const SizedBox(width: 8),
                                    const Text("|",
                                        style: TextStyle(color: Colors.grey)),
                                    const SizedBox(width: 8),
                                    Text(
                                        "${(data['Items'] as List).length} Items"),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                                    borderRadius: BorderRadius.circular(8)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text("Accept"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  _showConfirmationDialog(order.id, false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryRed,
                                side: const BorderSide(color: primaryRed),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text("Reject"),
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
    return StreamBuilder<QuerySnapshot>(
      stream: historyStream,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            _buildStatusFilter(),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final order = snapshot.data!.docs[index];
                  final data = order.data() as Map<String, dynamic>;
                  final status = data['Status'] ?? 'Unknown';

                  return Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () =>
                          _navigateToOrderDetails(context, order, true),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            if (data['Customer_ID'] != null)
                              _CustomerInfoWidget(data['Customer_ID'] as String)
                            else
                              const CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage(
                                    'https://i.imgur.com/OtAn7hT.jpeg'),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Order ${data['Order_Number'] ?? ''}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  Text(
                                    "${data['Total']?.toStringAsFixed(3)} BHD",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            _buildStatusPill(status),
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
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: historyStatuses.length,
        itemBuilder: (context, index) {
          final status = historyStatuses[index];
          final isSelected = status == selectedHistoryStatus;
          return GestureDetector(
            onTap: () => setState(() => selectedHistoryStatus = status),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? primaryRed : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    final Color bgColor = Colors.grey[200]!;
    Color textColor;
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
      default:
        textColor = Colors.black;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
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
