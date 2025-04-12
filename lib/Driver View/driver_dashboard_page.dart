import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'driver_side_bar.dart';

void main() {
  runApp(const DriverDashboard());
}

class DriverDashboard extends StatelessWidget {
  const DriverDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DriverOrdersChart(),
    );
  }
}

class DriverOrdersChart extends StatefulWidget {
  const DriverOrdersChart({super.key});

  @override
  _DriverOrdersChartState createState() => _DriverOrdersChartState();
}

class _DriverOrdersChartState extends State<DriverOrdersChart> {
  late List<OrderData> orderData = [];
  double highestSales = 0.0;
  int currentMenuIndex = 0;
  String driverId = "";
  String driverName = "Loading...";
  String driverImage = "https://i.imgur.com/OtAn7hT.jpeg";
  String vendorLogo = "";

  Map<String, dynamic>? currentOrder;
  double orderPrice = 0.0;
  int totalItems = 0;

  int todayOrders = 0;
  double todayRevenue = 0.0;
  int yesterdayOrders = 0;
  double yesterdayRevenue = 0.0;
  int totalOrders = 0;
  double totalRevenue = 0.0;

  bool isBusy = false;
  bool isLoadingStatus = true;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDriverData();
    _fetchCurrentOrder();
  }

  Future<void> _fetchDriverData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    driverId = user.uid;

    DocumentSnapshot driverDoc = await FirebaseFirestore.instance
        .collection('Driver')
        .doc(driverId)
        .get();

    if (driverDoc.exists) {
      setState(() {
        driverName = driverDoc.get('Name') ?? "Driver Name";
        driverImage =
            driverDoc.get('Photo') ?? "https://i.imgur.com/OtAn7hT.jpeg";
        totalOrders = driverDoc.get('Total_Orders') ?? 0;
        totalRevenue = (driverDoc.get('Total_Revenue') ?? 0.0).toDouble();
        isBusy = driverDoc.get('isBusy') ?? false;
        isLoadingStatus = false;
      });
    }

    DateTime now = DateTime.now();
    DateTime sevenDaysAgo = now.subtract(const Duration(days: 7));

    QuerySnapshot salesSnapshot = await FirebaseFirestore.instance
        .collection('Driver')
        .doc(driverId)
        .collection('Sales_Data')
        .where('Date', isGreaterThanOrEqualTo: sevenDaysAgo)
        .orderBy('Date', descending: true)
        .get();

    List<OrderData> tempData = [];
    for (var doc in salesSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      tempData.add(OrderData(
        DateFormat('E').format(data['Date'].toDate()),
        data['Orders'] ?? 0,
        'current',
        (data['Revenue'] ?? 0.0).toDouble(),
      ));
    }

    DateTime yesterday = now.subtract(const Duration(days: 1));
    DocumentSnapshot yesterdayDoc = await FirebaseFirestore.instance
        .collection('Driver')
        .doc(driverId)
        .collection('Sales_Data')
        .doc(DateFormat('yyyy-MM-dd').format(yesterday))
        .get();

    setState(() {
      orderData = tempData;
      todayOrders = orderData.isNotEmpty ? orderData.first.orders : 0;
      todayRevenue = orderData.isNotEmpty ? orderData.first.revenue : 0.0;
      yesterdayOrders = yesterdayDoc.exists ? yesterdayDoc.get('Orders') : 0;
      yesterdayRevenue = yesterdayDoc.exists
          ? (yesterdayDoc.get('Revenue') ?? 0.0).toDouble()
          : 0.0;

      if (orderData.isNotEmpty) {
        highestSales = orderData
            .map((e) => e.orders)
            .reduce((a, b) => a > b ? a : b)
            .toDouble();
      }

      isLoading = false;
    });
  }

  Future<void> _fetchCurrentOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    QuerySnapshot orderSnapshot = await FirebaseFirestore.instance
        .collection('order')
        .where('Driver_ID', isEqualTo: user.uid)
        .where('Status', whereIn: ['Preparing', 'On The Way'])
        .limit(1)
        .get();

    if (orderSnapshot.docs.isNotEmpty) {
      var order = orderSnapshot.docs.first.data() as Map<String, dynamic>;

      Timestamp orderDate = order['Order_Date'];
      String formattedDate = DateFormat('MMMM d, y').format(orderDate.toDate());

      DocumentSnapshot customerDoc = await FirebaseFirestore.instance
          .collection('Customer')
          .doc(order['Customer_ID'])
          .get();

      DocumentSnapshot vendorDoc = await FirebaseFirestore.instance
          .collection('vendor')
          .doc(order['Vendor_ID'])
          .get();

      setState(() {
        currentOrder = order;
        orderPrice = order['Total'] ?? 0.0;
        totalItems = (order['Items'] as List).length;
        currentOrder?['Customer_Name'] = customerDoc.get('Name') ?? 'Customer';
        currentOrder?['Formatted_Date'] = formattedDate;
        vendorLogo = vendorDoc['Logo'];
      });
    }
  }

  Map<String, dynamic> getTodayOrderData() {
    double dailyPercentageOrderChange = yesterdayOrders > 0
        ? ((todayOrders - yesterdayOrders) / yesterdayOrders) * 100
        : 0.0;

    Color dailyPercentageColor =
        dailyPercentageOrderChange >= 0 ? Colors.green : Colors.red;
    IconData dailyArrowIcon = dailyPercentageOrderChange >= 0
        ? Icons.arrow_upward
        : Icons.arrow_downward;

    return {
      "dailyOrders": todayOrders.toString(),
      "dailyRevenue": todayRevenue.toStringAsFixed(3),
      "dailyPercentageOrderChange":
          "${dailyPercentageOrderChange.toStringAsFixed(1)}%",
      "dailyPercentageColor": dailyPercentageColor,
      "dailyArrowIcon": dailyArrowIcon,
    };
  }

  Future<void> _toggleAvailability() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      isLoadingStatus = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('Driver')
          .doc(user.uid)
          .update({'isBusy': !isBusy});

      setState(() {
        isBusy = !isBusy;
        isLoadingStatus = false;
      });
    } catch (e) {
      setState(() {
        isLoadingStatus = false;
      });
      print("Error updating status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double cardWidth = (screenWidth - 70) / 2;

    var todayOrderData = getTodayOrderData();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFBF0000),
        elevation: 0,
        title: Column(
          children: [
            Text(
              "Dashboard",
              style: TextStyle(
                fontSize: screenWidth * 0.06,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
          ],
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) => Padding(
            padding: EdgeInsets.only(bottom: screenHeight * 0.008),
            child: IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFFBF0000),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(
                              left: screenWidth * 0.02,
                              top: screenHeight * 0.02),
                          child: Row(
                            children: [
                              CircleAvatar(
                                  radius: 20,
                                  backgroundImage: driverImage.isNotEmpty
                                      ? NetworkImage(driverImage)
                                      : const NetworkImage(
                                          'https://i.imgur.com/OtAn7hT.jpeg')),
                              const SizedBox(width: 8),
                              Text(
                                driverName,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: screenWidth * 0.08,
                          runSpacing: screenHeight * 0.02,
                          children: <Widget>[
                            _buildCard(
                              "Today's Orders",
                              todayOrderData["dailyOrders"] ?? "0",
                              todayOrderData["dailyPercentageOrderChange"] ??
                                  "0%",
                              cardWidth,
                              screenHeight,
                              percentageColor:
                                  todayOrderData["dailyPercentageColor"],
                              arrowIcon: todayOrderData["dailyArrowIcon"],
                            ),
                            _buildCard(
                              "Today's Revenue",
                              "BHD ${todayOrderData["dailyRevenue"]}",
                              todayOrderData["dailyPercentageOrderChange"] ??
                                  "0%",
                              cardWidth,
                              screenHeight,
                              percentageColor:
                                  todayOrderData["dailyPercentageColor"],
                              arrowIcon: todayOrderData["dailyArrowIcon"],
                            ),
                            _buildCard(
                                "Total Orders",
                                totalOrders.toString(),
                                "+${totalOrders.toStringAsFixed(1)}%",
                                cardWidth,
                                screenHeight,
                                percentageColor: Colors.green,
                                arrowIcon: Icons.arrow_upward,
                                showSinceYesterday: false),
                            _buildCard(
                                "Total Revenue",
                                "BHD ${totalRevenue.toStringAsFixed(3)}",
                                "+${(totalRevenue * 0.1).toStringAsFixed(1)}%",
                                cardWidth,
                                screenHeight,
                                percentageColor: Colors.green,
                                arrowIcon: Icons.arrow_upward,
                                showSinceYesterday: false),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        const Divider(),
                        const SizedBox(height: 20),
                        if (currentOrder != null) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              "Current Order",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          _buildCurrentOrderCard(
                            screenWidth: screenWidth,
                            screenHeight: screenHeight,
                            orderNumber: currentOrder!['Order_Number'] ?? '#47',
                            customerName:
                                currentOrder!['Customer_Name'] ?? 'Customer',
                            totalPrice: currentOrder!['Total'] ?? 0.0,
                            itemCount: totalItems,
                            imageUrl: vendorLogo,
                          ),
                          const Divider(),
                        ],
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(2, 2),
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "Daily Orders",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 200,
                                child: SfCartesianChart(
                                  primaryXAxis: CategoryAxis(),
                                  primaryYAxis: NumericAxis(),
                                  series: <CartesianSeries>[
                                    ColumnSeries<OrderData, String>(
                                      dataSource: orderData,
                                      xValueMapper: (OrderData data, _) =>
                                          data.day,
                                      yValueMapper: (OrderData data, _) =>
                                          data.orders,
                                      color: const Color(0xFFBF0000),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildAvailabilityButton(screenWidth),
              ],
            ),
      drawer: DrawerScreen(
        selectedIndex: currentMenuIndex,
        onItemTapped: (index) => setState(() => currentMenuIndex = index),
      ),
    );
  }

  Widget _buildCard(
    String title,
    String value,
    String percentage,
    double width,
    double screenHeight, {
    Color? percentageColor,
    IconData? arrowIcon,
    bool showSinceYesterday = true,
  }) {
    final cardHeight = screenHeight * 0.13;
    final padding = screenHeight * 0.012;
    final borderRadius = screenHeight * 0.012;
    final shadowBlur = screenHeight * 0.005;
    final shadowOffset = screenHeight * 0.0025;

    final titleSize = screenHeight * 0.015;
    final valueSizeNormal = screenHeight * 0.021;
    final valueSizeLarge = screenHeight * 0.023;
    final smallTextSize = screenHeight * 0.0125;
    final iconSize = screenHeight * 0.015;

    final smallSpacing = screenHeight * 0.01;
    final tinySpacing = screenHeight * 0.005;

    return Container(
      padding: EdgeInsets.all(padding),
      width: width,
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: shadowBlur,
            offset: Offset(shadowOffset, shadowOffset),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFBF0000),
            ),
          ),
          SizedBox(height: smallSpacing),
          Text(
            value,
            style: TextStyle(
              fontSize: showSinceYesterday ? valueSizeNormal : valueSizeLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: smallSpacing),
          Row(
            children: [
              if (showSinceYesterday) ...[
                if (percentageColor != null && arrowIcon != null)
                  Icon(arrowIcon, size: iconSize, color: percentageColor),
                SizedBox(width: tinySpacing),
                Text(
                  percentage,
                  style: TextStyle(
                    fontSize: smallTextSize,
                    fontWeight: FontWeight.bold,
                    color: percentageColor ?? Colors.black,
                  ),
                ),
                SizedBox(width: tinySpacing),
                Text(
                  "Since Yesterday",
                  style:
                      TextStyle(fontSize: smallTextSize, color: Colors.black),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentOrderCard({
    required double screenWidth,
    required double screenHeight,
    required String orderNumber,
    required String customerName,
    required double totalPrice,
    required int itemCount,
    required String imageUrl,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.0, vertical: screenHeight * 0.01),
      child: GestureDetector(
        onTap: () {
          print("Card Tapped!");
        },
        child: Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7.0),
          ),
          elevation: 3,
          child: Row(
            children: [
              Container(
                width: screenWidth * 0.227,
                height: screenHeight * 0.115,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7.0),
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
              Padding(
                padding: EdgeInsets.only(
                    top: screenWidth * 0.02,
                    right: screenWidth * 0.02,
                    bottom: screenWidth * 0.02),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          customerName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.09),
                        GestureDetector(
                          onTap: () {
                            print("ID $orderNumber Clicked!");
                          },
                          child: Text(
                            orderNumber,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 120, 121, 121),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Row(
                      children: [
                        Text(
                          "BHD ${totalPrice.toStringAsFixed(3)}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.05),
                        Text(" | "),
                        SizedBox(width: screenWidth * 0.05),
                        Text(
                          "$itemCount items",
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilityButton(double screenWidth) {
    bool disableToggle = isLoadingStatus || currentOrder != null;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: screenWidth * 0.9,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFBF0000),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: disableToggle ? null : _toggleAvailability,
          child: disableToggle
              ? const Text(
                  'Unavailable (Active Order)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Text(
                  isBusy ? 'Go Online' : 'Go Offline',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}

class OrderData {
  final String day;
  final int orders;
  final String weekType;
  final double revenue;

  OrderData(this.day, this.orders, this.weekType, this.revenue);
}
