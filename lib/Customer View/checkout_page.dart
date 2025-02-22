import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hometouch/Customer%20View/order_history_page.dart';
import 'package:intl/intl.dart';
import 'package:hometouch/Customer View/address_dialog.dart';

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double subtotal;
  final double tax;
  final int totalPoints;
  final double total;
  final Address selectedAddress;

  const CheckoutPage({
    Key? key,
    required this.cartItems,
    required this.subtotal,
    required this.tax,
    required this.totalPoints,
    required this.total,
    required this.selectedAddress,
  }) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int selectedPaymentMethod = 0;
  bool? useDelivery;
  bool? selectedTime;
  DateTime? scheduleTime;

  Future<int> _getNextOrderNumber() async {
    final orderCollection = FirebaseFirestore.instance.collection('order');
    final querySnapshot = await orderCollection
        .orderBy('Order_Number', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      String lastOrderNumber = querySnapshot.docs.first['Order_Number'] ?? "#0";

      int numericOrder = int.tryParse(lastOrderNumber.replaceAll("#", "")) ?? 0;

      return numericOrder + 1;
    }
    return 1;
  }

  Future<void> _placeOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      int orderNumber = await _getNextOrderNumber();

      String vendorId = widget.cartItems.isNotEmpty
          ? widget.cartItems.first["vendorId"].toString()
          : "Unknown";

      double roundedTotal = double.parse(widget.total.toStringAsFixed(3));

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Customer')
          .doc(user.uid)
          .get();

      int currentPoints = userDoc["Loyalty_Points"] ?? 0;

      if (widget.totalPoints > currentPoints) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "You dont have the requried loyalty points!",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(8),
          ),
        );

        return;
      }

      await FirebaseFirestore.instance.collection('order').add({
        "Customer_ID": user.uid,
        "Order_Number": "#$orderNumber",
        "Driver_ID": "eJXF01SPCo4QK3UApmpR",
        "Vendor_ID": vendorId,
        "Items": widget.cartItems,
        "Subtotal": widget.subtotal,
        "Tax": widget.tax,
        "Total": roundedTotal,
        "Total_Points_Used": widget.totalPoints,
        "Payment_Method": selectedPaymentMethod == 0
            ? "Card"
            : selectedPaymentMethod == 1
                ? "Benefit Pay"
                : "Cash",
        "Delivery_Type": useDelivery == true ? "Delivery" : "Pickup",
        "Time": selectedTime == true ? "Now" : "Scheduled",
        "Schedule_Time":
            scheduleTime != null ? Timestamp.fromDate(scheduleTime!) : null,
        "Status": "Preparing",
        "Order_Date": FieldValue.serverTimestamp(),
        "Customer_Address": {
          "Name": widget.selectedAddress.name,
          "Building": widget.selectedAddress.building,
          "Road": widget.selectedAddress.road,
          "Block": widget.selectedAddress.block,
          "Floor": widget.selectedAddress.floor,
          "Apartment": widget.selectedAddress.apartment,
          "Office": widget.selectedAddress.office,
          "Company_Name": widget.selectedAddress.companyName,
          "Location": widget.selectedAddress.location
        }
      });

      await FirebaseFirestore.instance
          .collection('Customer')
          .doc(user.uid)
          .update({
        "Loyalty_Points": FieldValue.increment(100 - widget.totalPoints),
      });

      _showSuccessDialog();

      await _clearCart(user.uid);

      Future.delayed(const Duration(seconds: 3), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OrdersPage()),
        );
      });
    } catch (e) {
      print("❌ Error placing order: $e");
    }
  }

  Future<void> _clearCart(String userId) async {
    try {
      var cartCollection = FirebaseFirestore.instance
          .collection('Customer')
          .doc(userId)
          .collection('cart');

      var cartItems = await cartCollection.get();

      for (var doc in cartItems.docs) {
        await doc.reference.delete();
      }

      print("✅ Cart cleared successfully!");
    } catch (e) {
      print("❌ Error clearing cart: $e");
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
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
              color: Color(0xFFBF0000),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              color: Colors.white,
              size: screenWidth * 0.12,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Order Placed',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Container(
                alignment: Alignment.center,
                child: Text(
                  'Please wait. You will be directed to the order history page',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.w300,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              CircularProgressIndicator(
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFFBF0000)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectScheduleTime() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFFBF0000),
            colorScheme: const ColorScheme.light(primary: Color(0xFFBF0000)),
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              primaryColor: const Color(0xFFBF0000),
              colorScheme: const ColorScheme.light(primary: Color(0xFFBF0000)),
              buttonTheme:
                  const ButtonThemeData(textTheme: ButtonTextTheme.primary),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          scheduleTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    bool isPayEnabled = useDelivery != null && selectedTime != null;

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
              'Checkout',
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.035),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                buildToggleButton('Delivery', true, screenWidth),
                SizedBox(width: screenWidth * 0.015),
                buildToggleButton('Pick up', false, screenWidth),
              ],
            ),
            SizedBox(height: screenHeight * 0.015),
            if (useDelivery != null)
              Row(
                children: [
                  buildTimeButton('Now', screenWidth, true),
                  SizedBox(width: screenWidth * 0.015),
                  buildTimeButton('Schedule', screenWidth, false),
                ],
              ),
            if (useDelivery != null) SizedBox(height: screenHeight * 0.015),
            if (selectedTime == false) ...[
              SizedBox(height: screenHeight * 0.012),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Scheduled Time: ",
                    style: TextStyle(
                      fontSize: screenHeight * 0.016,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    scheduleTime != null
                        ? DateFormat('dd MMM yyyy, hh:mm a')
                            .format(scheduleTime!)
                        : "Select Date & Time",
                    style: TextStyle(
                      fontSize: screenHeight * 0.016,
                      color: Color(0xFFBF0000),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.008),
              Center(
                child: ElevatedButton(
                  onPressed: _selectScheduleTime,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFFBF0000),
                    side: const BorderSide(color: Color(0xFFBF0000)),
                  ),
                  child: const Text("Choose Date & Time"),
                ),
              ),
            ],
            if (selectedTime == false && scheduleTime != null)
              SizedBox(height: screenHeight * 0.015),
            const Text('Pay With',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: screenHeight * 0.008),
            buildPaymentMethodTile(
                0, 'XXXX-1234', '12/25', Icons.credit_card, screenWidth),
            buildPaymentMethodTile(
                1, 'Benefit Pay', null, Icons.payment, screenWidth),
            buildPaymentMethodTile(2, 'Cash', null, Icons.money, screenWidth),
            SizedBox(height: screenHeight * 0.015),
            const Divider(thickness: 1, color: Colors.grey),
            SizedBox(height: screenHeight * 0.015),
            const Text('Coupon',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: screenHeight * 0.01),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.only(left: screenWidth * 0.04),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          offset: Offset(0, 4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Enter your promo code',
                        border: InputBorder.none,
                        suffixIcon: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFBF0000),
                          ),
                          child: IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.arrow_forward_ios,
                                color: Colors.white),
                            iconSize: screenWidth * 0.06,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.02),
            const Divider(thickness: 1, color: Colors.grey),
            SizedBox(height: screenHeight * 0.015),
            const Text('Payment Summary',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: screenHeight * 0.008),
            buildSummaryRow(
                'Subtotal', 'BHD ${widget.subtotal.toStringAsFixed(3)}'),
            buildSummaryRow('Tax', 'BHD ${widget.tax.toStringAsFixed(3)}'),
            Divider(thickness: 1, color: Colors.grey),
            buildSummaryRow('Total Points', 'Points ${widget.totalPoints}',
                isBold: true, isPoints: true),
            buildSummaryRow(
                'Total Amount', 'BHD ${widget.total.toStringAsFixed(3)}',
                isBold: true),
            SizedBox(height: screenHeight * 0.02),
            Center(
              child: ElevatedButton(
                onPressed: isPayEnabled ? _placeOrder : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isPayEnabled ? Color(0xFFBF0000) : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.35,
                    vertical: screenHeight * 0.018,
                  ),
                  textStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.04),
                ),
                child: const Text('Pay'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPaymentMethodTile(int index, String title, String? expiry,
      IconData icon, double screenWidth) {
    return InkWell(
      onTap: () {
        setState(() => selectedPaymentMethod = index);
      },
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.03),
        margin: EdgeInsets.symmetric(vertical: screenWidth * 0.01),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: selectedPaymentMethod == index
                ? Color(0xFFBF0000)
                : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selectedPaymentMethod == index
                    ? Color(0xFFBF0000)
                    : Colors.grey),
            SizedBox(width: screenWidth * 0.03),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            if (expiry != null) ...[
              SizedBox(width: screenWidth * 0.02),
              Text('Expiry: $expiry', style: TextStyle(color: Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildToggleButton(String text, bool isDelivery, double screenWidth) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            useDelivery = isDelivery;
            selectedTime = null;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              useDelivery == isDelivery ? Color(0xFFBF0000) : Colors.white,
          foregroundColor:
              useDelivery == isDelivery ? Colors.white : Colors.black,
        ),
        child: Text(text, style: TextStyle(fontSize: screenWidth * 0.035)),
      ),
    );
  }

  Widget buildTimeButton(String text, double screenWidth, bool isNow) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedTime = isNow;
            if (isNow) {
              scheduleTime = null;
            } else {
              _selectScheduleTime();
            }
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              selectedTime == isNow ? Color(0xFFBF0000) : Colors.white,
          foregroundColor: selectedTime == isNow ? Colors.white : Colors.black,
        ),
        child: Text(text, style: TextStyle(fontSize: screenWidth * 0.035)),
      ),
    );
  }

  Widget buildSummaryRow(String title, String amount,
      {bool isBold = false, bool isPoints = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: isBold ? 18 : 13,
                  color: isPoints ? Color(0xFFBF0000) : Colors.black)),
          Text(amount,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: isBold ? 18 : 13,
                  color: isPoints ? Color(0xFFBF0000) : Colors.black)),
        ],
      ),
    );
  }
}
