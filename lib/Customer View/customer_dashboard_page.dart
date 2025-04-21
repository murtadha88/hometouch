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
  int previousMonthOrders = 0;
  double previousMonthExpensive = 0.0;
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

    QuerySnapshot expensiveSnapshot = await FirebaseFirestore.instance
        .collection('Customer')
        .doc(customerId)
        .collection('Monthly_Expensive')
        .orderBy('Date', descending: true)
        .limit(2)
        .get();

    List<Map<String, dynamic>> months = [];

    if (expensiveSnapshot.docs.isNotEmpty) {
      months = expensiveSnapshot.docs
          .map((d) => d.data() as Map<String, dynamic>)
          .toList();

      monthlyOrders = months[0]['Orders'] ?? 0;
      monthlyExpensive = (months[0]['Expensive'] ?? 0.0).toDouble();
      if (months.length > 1) {
        previousMonthOrders = months[1]['Orders'] ?? 0;
        previousMonthExpensive = (months[1]['Expensive'] ?? 0.0).toDouble();
      }
    }

    setState(() {
      orderData = months
          .map((m) => OrderData(
                DateFormat('MMM').format((m['Date'] as Timestamp).toDate()),
                m['Orders'] ?? 0,
                (m['Expensive'] ?? 0.0).toDouble(),
              ))
          .toList();

      highestSpend = orderData.isNotEmpty
          ? orderData.map((e) => e.revenue).reduce((a, b) => a > b ? a : b)
          : 0.0;

      isLoading = false;
    });
  }

  Map<String, dynamic> getTotalMonthlyOrder() {
    final double change = previousMonthExpensive > 0
        ? ((monthlyExpensive - previousMonthExpensive) /
                previousMonthExpensive) *
            100
        : 0.0;
    final bool up = change >= 0;

    Color monthlyPercentageColor = up ? Colors.green : Colors.red;
    IconData monthlyArrowIcon = up ? Icons.arrow_upward : Icons.arrow_downward;

    return {
      "monthlyOrders": monthlyOrders.toString(),
      "monthlyExpensive": monthlyExpensive.toStringAsFixed(3),
      "change": "${change.toStringAsFixed(1)}%",
      "monthlyPercentageColor": monthlyPercentageColor,
      "monthlyArrowIcon": monthlyArrowIcon,
    };
  }

  Map<String, dynamic> getTotalMonthlyExpensive() {
    final double diff = monthlyExpensive - previousMonthExpensive;
    final double changePct = previousMonthExpensive > 0
        ? (diff / previousMonthExpensive) * 100
        : 0.0;

    final bool spentMore = diff > 0;
    final Color color = spentMore ? Colors.red : Colors.green;
    final IconData icon = spentMore ? Icons.arrow_upward : Icons.arrow_downward;

    return {
      "value": monthlyExpensive.toStringAsFixed(3),
      "change": "${changePct.abs().toStringAsFixed(1)}%",
      "color": color,
      "icon": icon,
    };
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double cardWidth = (screenWidth - 70) / 2;

    var monthlyOrdersData = getTotalMonthlyOrder();
    final spendDataMetrics = getTotalMonthlyExpensive();

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
                              monthlyOrdersData["monthlyOrders"] ?? "0",
                              monthlyOrdersData["change"] ?? "0%",
                              cardWidth,
                              screenHeight,
                              percentageColor:
                                  monthlyOrdersData["monthlyPercentageColor"],
                              arrowIcon: monthlyOrdersData["monthlyArrowIcon"],
                            ),
                            _buildCard(
                              "Monthly Spend",
                              "BHD ${spendDataMetrics["value"]}",
                              spendDataMetrics["change"],
                              cardWidth,
                              screenHeight,
                              percentageColor: spendDataMetrics["color"],
                              arrowIcon: spendDataMetrics["icon"],
                            ),
                            _buildCard(
                                "Total Orders",
                                totalOrders.toString(),
                                "+${totalOrders.toStringAsFixed(1)}%",
                                cardWidth,
                                screenHeight,
                                percentageColor: Colors.green,
                                arrowIcon: Icons.arrow_upward,
                                showSinceLastMonth: false),
                            _buildCard(
                                "Total Spend",
                                "BHD ${totalExpensive.toStringAsFixed(3)}",
                                "+${(totalExpensive * 0.1).toStringAsFixed(1)}%",
                                cardWidth,
                                screenHeight,
                                percentageColor: Colors.green,
                                arrowIcon: Icons.arrow_upward,
                                showSinceLastMonth: false),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        const Divider(),
                        if (orderData.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              "Monthly Spend Data",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          _buildMonthlyExpensiveChart(
                              screenWidth, screenHeight),
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
    bool showSinceLastMonth = true,
  }) {
    final cardHeight = screenHeight * 0.13;
    final padding = screenHeight * 0.012;
    final borderRadius = screenHeight * 0.012;
    final shadowBlur = screenHeight * 0.005;
    final shadowOffset = screenHeight * 0.0025;

    final titleSize = screenHeight * 0.015;
    final valueSizeNormal = screenHeight * 0.021;
    final valueSizeLarge = screenHeight * 0.023;
    final smallTextSize = screenHeight * 0.01;
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
              fontSize: showSinceLastMonth ? valueSizeNormal : valueSizeLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: smallSpacing),
          Row(
            children: [
              if (showSinceLastMonth) ...[
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
                  "Since Last Month",
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

  Widget _buildMonthlyExpensiveChart(double screenWidth, double screenHeight) {
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
            "Monthly Spend",
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
