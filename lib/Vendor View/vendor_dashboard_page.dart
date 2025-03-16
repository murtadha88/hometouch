import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
// import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'vendor_side_bar.dart';

class VendorDashboard extends StatefulWidget {
  const VendorDashboard({super.key});

  @override
  _VendorDashboardState createState() => _VendorDashboardState();
}

class SalesData {
  final String day;
  final String label;
  final double sales;
  final int orders;
  final DateTime date;

  SalesData(this.day, this.label, this.sales, this.orders, this.date);
}

class _VendorDashboardState extends State<VendorDashboard> {
  int selectedDayIndex = -1;
  late TrackballBehavior _trackballBehavior;
  late ZoomPanBehavior _zoomPanBehavior;

  List<SalesData> salesData = [];
  List<SalesData> lastWeekSalesData = [];

  int totalOrders = 0;
  double totalRevenue = 0.0;

  int lastWeekTotalOrders = 0;
  double lastWeekTotalRevenue = 0.0;
  int perDayOrders = 0;
  double perDayRevenue = 0.0;
  String perDayOrdersChange = "N/A";
  String perDayRevenueChange = "N/A";
  double highestSales = 0.0;
  int currentMonthOrders = 0;
  double currentMonthRevenue = 0.0;
  int previousMonthOrders = 0;
  double previousMonthRevenue = 0.0;
  String monthlyOrdersChange = "N/A";
  String monthlyRevenueChange = "N/A";
  int yesterdayOrders = 0;
  double yesterdayRevenue = 0.0;

  String totalOrdersChange = "N/A";
  String totalRevenueChange = "N/A";

  int newCustomerCurrent = 510;
  int newCustomerGoal = 500;
  int revenueCurrent = 15000;
  int revenueGoal = 15000;
  int currentMenuIndex = 0;
  String vendorName = "";
  String vendorLogo = "";
  double vendorRating = 0.0;

  String vendorId = "";

  @override
  void initState() {
    super.initState();
    _fetchVendorData();
    _trackballBehavior = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      tooltipSettings: InteractiveTooltip(
        enable: true,
        format: 'point.y BHD',
        borderColor: Colors.white,
      ),
      shouldAlwaysShow: true,
    );

    _zoomPanBehavior = ZoomPanBehavior(
      enablePanning: true,
      zoomMode: ZoomMode.x,
    );
  }

  Future<void> _fetchVendorData() async {
    final user = FirebaseAuth.instance.currentUser;
    try {
      if (user != null) {
        vendorId = user.uid;

        DocumentSnapshot vendorDoc = await FirebaseFirestore.instance
            .collection('vendor')
            .doc(vendorId)
            .get();

        QuerySnapshot salesSnapshot = await FirebaseFirestore.instance
            .collection('vendor')
            .doc(vendorId)
            .collection('Sales_Data')
            .orderBy('Date', descending: true)
            .get();

        // Fetch monthly sales data
        QuerySnapshot monthlySnapshot = await FirebaseFirestore.instance
            .collection('vendor')
            .doc(vendorId)
            .collection('Monthly_Sales')
            .orderBy('Date', descending: true)
            .limit(2)
            .get();

        if (vendorDoc.exists && salesSnapshot.docs.isNotEmpty) {
          final vendorData = vendorDoc.data() as Map<String, dynamic>;

          setState(() {
            vendorName = vendorData['Name'] ?? "";
            vendorLogo = vendorData['Logo'] ?? "";
            vendorRating = vendorData['Rating'] ?? 0.0;
            totalOrders = vendorData['Total_Orders'] ?? 0;
            totalRevenue = (vendorData['Total_Revenue'] ?? 0.0).toDouble();

            final monthlyDocs = monthlySnapshot.docs;
            if (monthlyDocs.isNotEmpty) {
              var currentMonthData =
                  monthlyDocs[0].data() as Map<String, dynamic>;
              currentMonthOrders = currentMonthData['Orders'] ?? 0;
              currentMonthRevenue =
                  (currentMonthData['Sales'] ?? 0.0).toDouble();

              if (monthlyDocs.length > 1) {
                var prevMonthData =
                    monthlyDocs[1].data() as Map<String, dynamic>;
                previousMonthOrders = prevMonthData['Orders'] ?? 0;
                previousMonthRevenue =
                    (prevMonthData['Sales'] ?? 0.0).toDouble();
              } else {
                previousMonthOrders = 0;
                previousMonthRevenue = 0.0;
              }
            } else {
              currentMonthOrders = 0;
              currentMonthRevenue = 0.0;
              previousMonthOrders = 0;
              previousMonthRevenue = 0.0;
            }

            salesData = salesSnapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return SalesData(
                data['Day'].toString(),
                data['Label'].toString(),
                (data['Sales'] ?? 0.0).toDouble(),
                (data['Orders'] ?? 0).toInt(),
                (data['Date'] as Timestamp).toDate(),
              );
            }).toList();

            DateTime today = DateTime.now();
            DateTime yesterday = today.subtract(Duration(days: 1));

            SalesData todaySales = salesData.firstWhere(
              (data) => isSameDay(data.date, today),
              orElse: () => SalesData("", "", 0.0, 0, DateTime.now()),
            );

            SalesData yesterdaySales = salesData.firstWhere(
              (data) => isSameDay(data.date, yesterday),
              orElse: () => SalesData("", "", 0.0, 0, DateTime.now()),
            );

            perDayOrders = todaySales.orders;
            perDayRevenue = todaySales.sales;
            yesterdayOrders = yesterdaySales.orders;
            yesterdayRevenue = yesterdaySales.sales;

            perDayOrdersChange = calculatePercentageChange(
                perDayOrders.toDouble(), yesterdayOrders.toDouble());
            perDayRevenueChange =
                calculatePercentageChange(perDayRevenue, yesterdayRevenue);

            monthlyOrdersChange = calculatePercentageChange(
                currentMonthOrders.toDouble(), previousMonthOrders.toDouble());
            monthlyRevenueChange = calculatePercentageChange(
                currentMonthRevenue, previousMonthRevenue);

            highestSales = salesData.isNotEmpty
                ? salesData.map((e) => e.sales).reduce(max)
                : 0.0;
          });
        }
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String calculatePercentageChange(double current, double previous) {
    if (previous == 0) return "N/A";
    double change = ((current - previous) / previous) * 100;
    return "${change.toStringAsFixed(1)}%";
  }

  List<SalesData> _getLastSevenDaysData(DateTime today) {
    DateTime sevenDaysAgo = today.subtract(const Duration(days: 6));
    return salesData
        .where((data) =>
            data.date.isAfter(sevenDaysAgo) ||
            data.date.isAtSameMomentAs(sevenDaysAgo))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double cardWidth = (screenWidth - 60) / 2;
    DateTime today = DateTime.now();
    List<SalesData> lastSevenDaysData = _getLastSevenDaysData(today);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFBF0000),
        elevation: 0,
        title: Column(
          children: [
            Text(
              "Dashboard",
              style: TextStyle(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
          ],
        ),
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
      body: salesData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(
                        left: screenWidth * 0.02,
                        right: screenWidth * 0.05,
                        top: screenHeight * 0.02),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(vendorLogo),
                            ),
                            SizedBox(width: 8),
                            Text(vendorName,
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.star, color: Color(0xFFBF0000)),
                            Text(vendorRating.toStringAsFixed(1),
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Wrap(
                    spacing: screenWidth * 0.01,
                    runSpacing: screenHeight * 0.01,
                    children: [
                      _buildCard(
                          "Per Day Orders",
                          perDayOrders.toString(),
                          perDayOrdersChange,
                          cardWidth,
                          Icons.access_time,
                          "Since Yesterday"),
                      _buildCard(
                          "Per Day Revenue",
                          perDayRevenue.toStringAsFixed(3),
                          perDayRevenueChange,
                          cardWidth,
                          Icons.attach_money,
                          "Since Yesterday"),
                      _buildCard(
                          "Monthly Orders",
                          "$currentMonthOrders",
                          monthlyOrdersChange,
                          cardWidth,
                          Icons.calendar_today,
                          "Since Last Month"),
                      _buildCard(
                          "Monthly Revenue",
                          currentMonthRevenue.toStringAsFixed(3),
                          monthlyRevenueChange,
                          cardWidth,
                          Icons.money,
                          "Since Last Month"),
                      _buildCard(
                          "Total Orders",
                          "$totalOrders",
                          totalOrdersChange,
                          cardWidth,
                          Icons.shopping_cart,
                          "Overall Total"),
                      _buildCard(
                          "Total Revenue",
                          totalRevenue.toStringAsFixed(3),
                          totalRevenueChange,
                          cardWidth,
                          Icons.money,
                          "Overall Total"),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                              top: screenHeight * 0.02,
                              left: screenWidth * 0.29),
                          child: Text("Weekly Sales",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Container(
                          margin: const EdgeInsets.only(right: 16.0),
                          width: 350,
                          height: 300,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: 700,
                              child: SfCartesianChart(
                                primaryXAxis: CategoryAxis(
                                  isInversed: true,
                                  opposedPosition: true,
                                  labelRotation: 0,
                                  labelStyle: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  title: AxisTitle(
                                    textStyle: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  majorGridLines: MajorGridLines(
                                    width: 1,
                                    color: Colors.white,
                                  ),
                                  maximumLabels: 8,
                                  axisLine: AxisLine(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                ),
                                primaryYAxis: NumericAxis(
                                  isVisible: true,
                                  opposedPosition: true,
                                  axisLine: AxisLine(
                                    width: 1,
                                    color: Colors.white,
                                  ),
                                  labelStyle:
                                      TextStyle(color: Colors.transparent),
                                  majorGridLines: MajorGridLines(
                                    width: 1,
                                    color: Colors.white,
                                  ),
                                ),
                                zoomPanBehavior: _zoomPanBehavior,
                                trackballBehavior: _trackballBehavior,
                                series: <CartesianSeries<SalesData, String>>[
                                  AreaSeries<SalesData, String>(
                                    dataSource: lastSevenDaysData,
                                    xValueMapper: (SalesData sales, _) =>
                                        "${sales.label}\n${sales.day}",
                                    yValueMapper: (SalesData sales, _) =>
                                        sales.sales,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.red.shade700,
                                        Colors.white
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderColor: Colors.red,
                                    borderWidth: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Best Sales",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text("BHD ${highestSales.toStringAsFixed(3)}",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Divider(color: Colors.black),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Today Sales",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                      "BHD ${salesData.isNotEmpty ? salesData.first.sales.toStringAsFixed(3) : '0.00'}",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // SizedBox(height: screenHeight * 0.04),
                  // Text("Monthly Performance",
                  //     style:
                  //         TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  // SizedBox(height: screenHeight * 0.01),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     _buildProgress(
                  //         "New Customers", newCustomerCurrent, newCustomerGoal),
                  //     _buildProgress("Revenue", revenueCurrent, revenueGoal),
                  //   ],
                  // ),
                  // SizedBox(height: screenHeight * 0.02),
                  // Text("Overall Performance Score",
                  //     style:
                  //         TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  // SizedBox(height: screenHeight * 0.01),
                  // _buildImprovementContainer(),
                  // SizedBox(height: screenHeight * 0.03),
                ],
              ),
            ),
      drawer: DrawerScreen(
        selectedIndex: currentMenuIndex,
        onItemTapped: (index) => setState(() => currentMenuIndex = index),
      ),
    );
  }

  Widget _buildCard(String title, String value, String percentage, double width,
      IconData icon, String comparisonText) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTotalCard = title == "Total Orders" || title == "Total Revenue";

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.02),
      margin: EdgeInsets.all(screenWidth * 0.01),
      width: width,
      height: screenHeight * 0.12,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(2, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFBF0000))),
                SizedBox(height: screenHeight * 0.01),
                Text(value,
                    style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold)),
                if (!isTotalCard) SizedBox(height: screenHeight * 0.005),
                if (!isTotalCard)
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                            text: "$percentage ",
                            style: TextStyle(
                                color: percentage != "N/A"
                                    ? (double.parse(percentage.replaceAll(
                                                '%', '')) >=
                                            0
                                        ? Colors.green
                                        : Colors.red)
                                    : Colors.black,
                                fontSize: screenWidth * 0.025,
                                fontWeight: FontWeight.bold)),
                        TextSpan(
                          text: comparisonText.isEmpty ? "" : comparisonText,
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: screenWidth * 0.022,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
              ],
            ),
          ),
          // Align(
          //   alignment: Alignment.bottomRight,
          //   child: Container(
          //     padding: EdgeInsets.all(screenWidth * 0.015),
          //     decoration: BoxDecoration(
          //       color: Color(0xFFBF0000).withOpacity(0.3),
          //       shape: BoxShape.circle,
          //     ),
          //     child: Icon(icon,
          //         color: Color(0xFFBF0000), size: screenWidth * 0.05),
          //   ),
          // ),
        ],
      ),
    );
  }

  // Widget _buildProgress(String title, int current, int goal) {
  //   double progress = current / goal;
  //   bool isGoalAchieved = current >= goal;

  //   return Expanded(
  //     child: Container(
  //       padding: const EdgeInsets.all(16.0),
  //       margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.circular(10),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.black26,
  //             blurRadius: 6,
  //             spreadRadius: 2,
  //             offset: Offset(2, 4),
  //           ),
  //         ],
  //       ),
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         crossAxisAlignment: CrossAxisAlignment.center,
  //         children: [
  //           Text(
  //             title,
  //             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
  //           ),
  //           SizedBox(height: 8),
  //           SizedBox(
  //             height: 150,
  //             child: SfRadialGauge(
  //               axes: <RadialAxis>[
  //                 RadialAxis(
  //                   minimum: 0,
  //                   maximum: 1,
  //                   showLabels: false,
  //                   showTicks: false,
  //                   startAngle: 135,
  //                   endAngle: 45,
  //                   axisLineStyle: AxisLineStyle(
  //                     thickness: 0.15,
  //                     thicknessUnit: GaugeSizeUnit.factor,
  //                     color: Colors.grey.shade300,
  //                   ),
  //                   annotations: <GaugeAnnotation>[
  //                     GaugeAnnotation(
  //                       widget: Column(
  //                         mainAxisSize: MainAxisSize.min,
  //                         children: [
  //                           Icon(
  //                             isGoalAchieved
  //                                 ? Icons.check_circle
  //                                 : (title == "New Customers"
  //                                     ? Icons.person
  //                                     : (title == "Revenue"
  //                                         ? Icons.attach_money_outlined
  //                                         : Icons.error)),
  //                             color: isGoalAchieved
  //                                 ? Colors.green
  //                                 : Color(0xFFBF0000),
  //                             size: 24,
  //                           ),
  //                           SizedBox(height: 4),
  //                           Text(
  //                             "$current",
  //                             style: TextStyle(
  //                               fontSize: 18,
  //                               fontWeight: FontWeight.bold,
  //                               color: isGoalAchieved
  //                                   ? const Color.fromARGB(255, 5, 77, 7)
  //                                   : Color(0xFFBF0000),
  //                             ),
  //                           ),
  //                           SizedBox(height: 4),
  //                           Text(
  //                             title == "Revenue"
  //                                 ? "BHD"
  //                                 : title == "New Customers"
  //                                     ? "Customer"
  //                                     : "",
  //                             style: TextStyle(
  //                                 fontSize: 12, color: Colors.black54),
  //                           ),
  //                         ],
  //                       ),
  //                       angle: 90,
  //                       positionFactor: 0.1,
  //                     ),
  //                   ],
  //                   pointers: <GaugePointer>[
  //                     RangePointer(
  //                       value: progress,
  //                       width: 0.15,
  //                       sizeUnit: GaugeSizeUnit.factor,
  //                       color: isGoalAchieved
  //                           ? Colors.green
  //                           : const Color.fromARGB(255, 187, 24, 12),
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //           SizedBox(height: 8),
  //           Text(
  //             title == "Revenue" ? "Goal: $goal " : "Goal: $goal",
  //             style: TextStyle(
  //                 fontSize: 14,
  //                 color: Colors.black,
  //                 fontWeight: FontWeight.bold),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildImprovementContainer() {
  //   double customerProgress = newCustomerCurrent / newCustomerGoal;
  //   double revenueProgress = revenueCurrent / revenueGoal;

  //   double overallProgress = (customerProgress + revenueProgress) / 2;
  //   int overallPercentage = (overallProgress * 100).round();

  //   Color progressColor;
  //   if (overallProgress < 0.25) {
  //     progressColor = Colors.red;
  //   } else if (overallProgress >= 0.25 && overallProgress < 0.50) {
  //     progressColor = Color.fromARGB(255, 243, 147, 14);
  //   } else if (overallProgress >= 0.50 && overallProgress < 0.75) {
  //     progressColor = Colors.yellow;
  //   } else if (overallProgress >= 0.75 && overallProgress <= 1.0) {
  //     progressColor = Colors.green;
  //   } else {
  //     progressColor = Color(0xFF6A1B9A);
  //   }

  //   return Container(
  //     padding: EdgeInsets.all(16.0),
  //     margin: EdgeInsets.symmetric(vertical: 8.0),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(10),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black26,
  //           blurRadius: 6,
  //           spreadRadius: 2,
  //           offset: Offset(2, 4),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       mainAxisSize: MainAxisSize.min,
  //       crossAxisAlignment: CrossAxisAlignment.center,
  //       children: [
  //         SizedBox(
  //           height: 150,
  //           child: SfRadialGauge(
  //             axes: <RadialAxis>[
  //               RadialAxis(
  //                 minimum: 0,
  //                 maximum: 1,
  //                 showLabels: false,
  //                 showTicks: false,
  //                 startAngle: 180,
  //                 endAngle: 0,
  //                 axisLineStyle: AxisLineStyle(
  //                   thickness: 0.15,
  //                   thicknessUnit: GaugeSizeUnit.factor,
  //                   color: Colors.grey.shade300,
  //                 ),
  //                 annotations: <GaugeAnnotation>[
  //                   GaugeAnnotation(
  //                     widget: Column(
  //                       mainAxisSize: MainAxisSize.min,
  //                       children: [
  //                         Icon(
  //                           Icons.trending_up,
  //                           color: progressColor,
  //                           size: 24,
  //                         ),
  //                         SizedBox(height: 4),
  //                         Text(
  //                           "$overallPercentage%",
  //                           style: TextStyle(
  //                             fontSize: 24,
  //                             fontWeight: FontWeight.bold,
  //                             color: progressColor,
  //                           ),
  //                         ),
  //                         SizedBox(height: 18),
  //                       ],
  //                     ),
  //                     angle: 90,
  //                     positionFactor: 0.1,
  //                   ),
  //                 ],
  //                 pointers: <GaugePointer>[
  //                   RangePointer(
  //                     value: overallProgress,
  //                     width: 0.15,
  //                     sizeUnit: GaugeSizeUnit.factor,
  //                     color: progressColor,
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
