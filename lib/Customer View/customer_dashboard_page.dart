import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomerOrdersChart();
  }
}

class CustomerOrdersChart extends StatefulWidget {
  const CustomerOrdersChart({super.key});

  @override
  _CustomerOrdersChartState createState() => _CustomerOrdersChartState();
}

class _CustomerOrdersChartState extends State<CustomerOrdersChart> {
  late List<OrderData> orderData = [];
  double highestSpend = 0.0;
  int currentMenuIndex = 0;
  String customerId = "";
  String customerName = "Loading...";
  String customerImage = "https://i.imgur.com/OtAn7hT.jpeg";

  int monthlyOrders = 0;
  double monthlyExpensive = 0.0;
  int yesterdayOrders = 0;
  double yesterdaySpend = 0.0;
  int totalOrders = 0;
  double totalExpensive = 0.0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCustomerData();
  }

  Future<void> _fetchCustomerData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    customerId = user.uid;

    DocumentSnapshot customerDoc = await FirebaseFirestore.instance
        .collection('Customer')
        .doc(customerId)
        .get();

    if (customerDoc.exists) {
      setState(() {
        customerName = customerDoc.get('Name') ?? "Customer Name";
        customerImage =
            customerDoc.get('Photo') ?? "https://i.imgur.com/OtAn7hT.jpeg";
        totalOrders = customerDoc.get('Total_Orders') ?? 0;
        totalExpensive = (customerDoc.get('Total_Expensive') ?? 0.0).toDouble();
      });
    }

    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);

    QuerySnapshot salesSnapshot = await FirebaseFirestore.instance
        .collection('Customer')
        .doc(customerId)
        .collection('Monthly_Sales')
        .where('Date', isGreaterThanOrEqualTo: startOfMonth)
        .orderBy('Date', descending: true)
        .get();

    List<OrderData> tempData = [];
    for (var doc in salesSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      tempData.add(OrderData(
        DateFormat('MMM').format(data['Date'].toDate()),
        data['Orders'] ?? 0,
        (data['Total_Expensive'] ?? 0.0).toDouble(),
      ));
    }

    DateTime yesterday = now.subtract(const Duration(days: 1));
    DocumentSnapshot yesterdayDoc = await FirebaseFirestore.instance
        .collection('Customer')
        .doc(customerId)
        .collection('Sales_Data')
        .doc(DateFormat('yyyy-MM-dd').format(yesterday))
        .get();

    setState(() {
      orderData = tempData;
      monthlyOrders = orderData.isNotEmpty ? orderData.first.orders : 0;
      monthlyExpensive = orderData.isNotEmpty ? orderData.first.revenue : 0.0;
      yesterdayOrders = yesterdayDoc.exists ? yesterdayDoc.get('Orders') : 0;
      yesterdaySpend = yesterdayDoc.exists
          ? (yesterdayDoc.get('Total_Expensive') ?? 0.0).toDouble()
          : 0.0;

      if (orderData.isNotEmpty) {
        highestSpend = orderData
            .map((e) => e.revenue)
            .reduce((a, b) => a > b ? a : b)
            .toDouble();
      }

      isLoading = false;
    });
  }

  Map<String, dynamic> getTotalMonthlyOrder() {
    double dailyPercentageOrderChange = yesterdayOrders > 0
        ? ((monthlyOrders - yesterdayOrders) / yesterdayOrders) * 100
        : 0.0;

    Color dailyPercentageColor =
        dailyPercentageOrderChange >= 0 ? Colors.green : Colors.red;
    IconData dailyArrowIcon = dailyPercentageOrderChange >= 0
        ? Icons.arrow_upward
        : Icons.arrow_downward;

    return {
      "dailyOrders": monthlyOrders.toString(),
      "dailySpend": monthlyExpensive.toStringAsFixed(3),
      "dailyPercentageOrderChange":
          "${dailyPercentageOrderChange.toStringAsFixed(1)}%",
      "dailyPercentageColor": dailyPercentageColor,
      "dailyArrowIcon": dailyArrowIcon,
    };
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double cardWidth = (screenWidth - 70) / 2;

    var monthlyOrdersData = getTotalMonthlyOrder();

    return Scaffold(
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
                  color: Color(0xFFBF0000),
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
              'Overview',
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
                    padding: EdgeInsets.only(
                        left: screenWidth * 0.04,
                        right: screenWidth * 0.04,
                        bottom: screenWidth * 0.04),
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
                                  backgroundImage: customerImage.isNotEmpty
                                      ? NetworkImage(customerImage)
                                      : const NetworkImage(
                                          'https://i.imgur.com/OtAn7hT.jpeg')),
                              const SizedBox(width: 8),
                              Text(
                                customerName,
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
                              "Monthly Orders",
                              monthlyOrdersData["dailyOrders"] ?? "0",
                              monthlyOrdersData["dailyPercentageOrderChange"] ??
                                  "0%",
                              cardWidth,
                              screenHeight,
                              percentageColor:
                                  monthlyOrdersData["dailyPercentageColor"],
                              arrowIcon: monthlyOrdersData["dailyArrowIcon"],
                            ),
                            _buildCard(
                              "Monthly Expensive",
                              "BHD ${monthlyOrdersData["dailySpend"]}",
                              monthlyOrdersData["dailyPercentageOrderChange"] ??
                                  "0%",
                              cardWidth,
                              screenHeight,
                              percentageColor:
                                  monthlyOrdersData["dailyPercentageColor"],
                              arrowIcon: monthlyOrdersData["dailyArrowIcon"],
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
                                "Total Expensive",
                                "BHD ${totalExpensive.toStringAsFixed(3)}",
                                "+${(totalExpensive * 0.1).toStringAsFixed(1)}%",
                                cardWidth,
                                screenHeight,
                                percentageColor: Colors.green,
                                arrowIcon: Icons.arrow_upward,
                                showSinceYesterday: false),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        const Divider(),
                        if (orderData.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              "Monthly Orders Data",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          _buildMonthlySalesChart(screenWidth, screenHeight),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
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

  Widget _buildMonthlySalesChart(double screenWidth, double screenHeight) {
    return Container(
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
            "Monthly Orders",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 200,
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              primaryYAxis: NumericAxis(),
              series: <CartesianSeries>[
                ColumnSeries<OrderData, String>(
                  dataSource: orderData,
                  xValueMapper: (OrderData data, _) => data.day,
                  yValueMapper: (OrderData data, _) => data.revenue,
                  color: const Color(0xFFBF0000),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OrderData {
  final String day;
  final int orders;
  final double revenue;

  OrderData(this.day, this.orders, this.revenue);
}
