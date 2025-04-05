import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import "driver_side_bar.dart";
import 'package:intl/intl.dart';

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
  late List<OrderData> orderData;
  late double highestSales;

  double orderPrice = 7.350;
  int currentMenuIndex = 0;

  String getTodayDay() {
    return DateFormat('E').format(DateTime.now());
  }

  Map<String, dynamic> getTodayOrderData() {
    String today = getTodayDay();

    OrderData currentData = orderData.firstWhere(
      (e) => e.day == today && e.weekType == 'current',
      orElse: () => OrderData(today, 0, 'current', 0.0),
    );

    OrderData previousData = orderData.firstWhere(
      (e) => e.day == today && e.weekType == 'previous',
      orElse: () => OrderData(today, 0, 'previous', 0.0),
    );

    double dailyPercentageOrderChange = previousData.orders > 0
        ? ((currentData.orders - previousData.orders) / previousData.orders) *
            100
        : 0.0;

    Color dailyPercentageColor =
        dailyPercentageOrderChange >= 0 ? Colors.green : Colors.red;
    IconData dailyArrowIcon = dailyPercentageOrderChange >= 0
        ? Icons.arrow_upward
        : Icons.arrow_downward;

    int totalOrdersCurrentWeek = orderData
        .where((e) => e.weekType == 'current')
        .fold(0, (sum, e) => sum + e.orders);

    int totalOrdersPreviousWeek = orderData
        .where((e) => e.weekType == 'previous')
        .fold(0, (sum, e) => sum + e.orders);

    double totalPercentageOrderChange = totalOrdersPreviousWeek > 0
        ? ((totalOrdersCurrentWeek - totalOrdersPreviousWeek) /
                totalOrdersPreviousWeek) *
            100
        : 0.0;

    Color totalPercentageColor =
        totalPercentageOrderChange >= 0 ? Colors.green : Colors.red;
    IconData totalArrowIcon = totalPercentageOrderChange >= 0
        ? Icons.arrow_upward
        : Icons.arrow_downward;

    return {
      // Daily orders data
      "dailyOrders": currentData.orders.toString(),
      "dailyPercentageOrderChange":
          "${dailyPercentageOrderChange.toStringAsFixed(1)}%",
      "dailyPercentageColor": dailyPercentageColor,
      "dailyArrowIcon": dailyArrowIcon,

      // Total orders data
      "totalOrdersCurrentWeek": totalOrdersCurrentWeek.toString(),
      "totalOrdersPreviousWeek": totalOrdersPreviousWeek.toString(),
      "percentageTotalOrderChange":
          "${totalPercentageOrderChange.toStringAsFixed(1)}%",
      "totalPercentageColor": totalPercentageColor,
      "totalArrowIcon": totalArrowIcon,
    };
  }

  @override
  void initState() {
    super.initState();
    orderData = getFakeOrderData();

    if (orderData.isNotEmpty) {
      highestSales = orderData
          .map((e) => e.orders)
          .reduce((a, b) => a > b ? a : b)
          .toDouble();
    } else {
      highestSales = 0.0;
    }
  }

  List<OrderData> getFakeOrderData() {
    return [
      // Current week data
      OrderData('Sun', 12, 'current', 120.0),
      OrderData('Mon', 15, 'current', 150.0),
      OrderData('Tue', 10, 'current', 50.0),
      OrderData('Wed', 17, 'current', 180.0),
      OrderData('Thu', 14, 'current', 140.0),
      OrderData('Fri', 20, 'current', 200.0),
      OrderData('Sat', 14, 'current', 40.0),

// Previous week data
      OrderData('Sun', 10, 'previous', 100.0),
      OrderData('Mon', 13, 'previous', 130.0),
      OrderData('Tue', 12, 'previous', 120.0),
      OrderData('Wed', 20, 'previous', 200.0),
      OrderData('Thu', 15, 'previous', 150.0),
      OrderData('Fri', 18, 'previous', 180.0),
      OrderData('Sat', 3, 'previous', 140.0),
    ];
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
        title: const Text(
          "Dashboard",
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Profile Section
            Padding(
              padding: EdgeInsets.only(
                  left: screenWidth * 0.02, top: screenHeight * 0.02),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundImage: AssetImage('assets/your_image.png'),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "John Doe",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Stats Cards
            Wrap(
              spacing: screenWidth * 0.08,
              runSpacing: screenHeight * 0.02,
              children: <Widget>[
                _buildCard(
                  "Per Day Orders",
                  todayOrderData["dailyOrders"] ??
                      "0", // Daily orders for today
                  todayOrderData["dailyPercentageOrderChange"] ??
                      "0%", // Percentage change
                  cardWidth,
                  screenHeight,
                  percentageColor: todayOrderData[
                      "dailyPercentageColor"], // Color for daily orders
                  arrowIcon: todayOrderData[
                      "dailyArrowIcon"], // Arrow icon for daily orders
                ),
                _buildCard(
                  "Total Orders",
                  todayOrderData["totalOrdersCurrentWeek"] ??
                      "0", // Total orders for the week
                  todayOrderData["percentageTotalOrderChange"] ??
                      "0%", // Percentage change
                  cardWidth,
                  screenHeight,
                  percentageColor: todayOrderData[
                      "totalPercentageColor"], // Color for total orders
                  arrowIcon: todayOrderData[
                      "totalArrowIcon"], // Arrow icon for total orders
                ),
              ],
            ),

            SizedBox(height: screenHeight * 0.02),
            Divider(
              color: Colors.black26,
              thickness: 1,
              indent: screenWidth * 0.01,
              endIndent: screenWidth * 0.01,
            ),
            const SizedBox(height: 20),
            Text(
              "Current Order",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Container(
              height: screenHeight * 0.15,
              child: _buildCurrentCustomerCard(
                index: 0,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                title: "Customer Name",
                price: orderPrice,
                items: 3,
                imageUrl: "https://i.imgur.com/aMJClNe.jpeg",
                id: 12345,
                onCardTap: () {
                  print("Card Tapped!");
                },
                onIdTap: () {
                  print("ID #12345 Clicked!");
                },
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Divider(
              color: Colors.black26,
              thickness: 1,
              indent: screenWidth * 0.01,
              endIndent: screenWidth * 0.01,
            ),
            const SizedBox(height: 20),

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      "Daily Orders",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Chart
                  SizedBox(
                    height: 200,
                    child: SfCartesianChart(
                      plotAreaBorderColor: Colors.white,
                      primaryXAxis: CategoryAxis(
                        title: AxisTitle(text: ''),
                        plotOffset: 10,
                        majorTickLines: MajorTickLines(width: 0),
                        axisLine: AxisLine(width: 1, color: Colors.white),
                        majorGridLines: MajorGridLines(width: 0),
                      ),
                      primaryYAxis: NumericAxis(
                        title: AxisTitle(text: ''),
                        majorGridLines: MajorGridLines(width: 0),
                        axisLine: AxisLine(width: 1, color: Colors.white),
                        majorTickLines: MajorTickLines(width: 0),
                      ),
                      series: <CartesianSeries>[
                        ColumnSeries<OrderData, String>(
                          dataSource: orderData
                              .where((data) => data.weekType == 'current')
                              .toList(),
                          xValueMapper: (OrderData data, _) => data.day,
                          yValueMapper: (OrderData data, _) => data.orders,
                          dataLabelSettings:
                              DataLabelSettings(isVisible: false),
                          color: Color(0xFFBF0000),
                          borderRadius: BorderRadius.circular(10),
                          width: 0.3,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
      //----------------------- Drawer (for menu icon)-----------------------
      drawer: DrawerScreen(
        selectedIndex: currentMenuIndex,
        onItemTapped: (index) {
          setState(() {
            currentMenuIndex = index;
          });
        },
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
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      width: width,
      height: 100,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFFBF0000),
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: screenHeight * 0.01),
          Row(
            children: [
              if (percentageColor != null && arrowIcon != null)
                Icon(arrowIcon,
                    size: 12,
                    color: percentageColor), // Use the passed icon and color
              const SizedBox(width: 4),
              Text(
                percentage,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color:
                      percentageColor ?? Colors.black, // Use the passed color
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                "Since Last Week",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentCustomerCard({
    required int index,
    required double screenWidth,
    required double screenHeight,
    required String title,
    required double price,
    required int items,
    required String imageUrl,
    required Function() onCardTap,
    required int id,
    required Function() onIdTap,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.0, vertical: screenHeight * 0.01),
      child: GestureDetector(
        onTap: onCardTap,
        child: Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7.0),
          ),
          elevation: 3,
          child: Row(
            children: [
              Container(
                width: screenWidth * 0.23,
                height: screenHeight * 0.2,
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
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.09),
                        GestureDetector(
                          onTap: onIdTap,
                          child: Text(
                            "#$id",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 120, 121, 121),
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
                          "$price BHD",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.05),
                        Text(" | "),
                        SizedBox(width: screenWidth * 0.05),
                        Text(items.toString()),
                        Text(
                          " items",
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
}

class OrderData {
  final String day;
  final int orders;
  final String weekType;
  final double revenue;

  OrderData(this.day, this.orders, this.weekType, this.revenue);
}
