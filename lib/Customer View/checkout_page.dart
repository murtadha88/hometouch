import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double subtotal;
  final double tax;
  final double total;

  const CheckoutPage({
    Key? key,
    required this.cartItems,
    required this.subtotal,
    required this.tax,
    required this.total,
  }) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int selectedPaymentMethod = 0; // 0: Card, 1: Benefit Pay, 2: Cash
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

      // Extract the numeric part safely
      int numericOrder = int.tryParse(lastOrderNumber.replaceAll("#", "")) ?? 0;

      return numericOrder + 1;
    }
    return 1; // First order
  }

  Future<void> _placeOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      int orderNumber = await _getNextOrderNumber();

      String vendorId = widget.cartItems.isNotEmpty
          ? widget.cartItems.first["vendorId"].toString()
          : "Unknown";

      await FirebaseFirestore.instance.collection('order').add({
        "Customer_ID": user.uid,
        "Order_Number": "#$orderNumber", // ✅ Always stored as a string with "#"
        "Vendor_ID": vendorId, // ✅ Ensure it's a String
        "Items": widget.cartItems,
        "Subtotal": widget.subtotal,
        "Tax": widget.tax,
        "Total": widget.total,
        "Payment_Method": selectedPaymentMethod == 0
            ? "Card"
            : selectedPaymentMethod == 1
                ? "Benefit Pay"
                : "Cash",
        "Delivery_Type": useDelivery == true ? "Delivery" : "Pickup",
        "Time": selectedTime == true ? "Now" : "Scheduled",
        "Schedule_Time":
            scheduleTime != null ? Timestamp.fromDate(scheduleTime!) : null,
        "Status": "In Progress",
        "Order_Date": FieldValue.serverTimestamp(),
      });

      // Clear Cart
      final cartRef = FirebaseFirestore.instance
          .collection('Customer')
          .doc(user.uid)
          .collection('cart');
      var cartDocs = await cartRef.get();
      for (var doc in cartDocs.docs) {
        await doc.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order placed successfully!")),
      );
    } catch (e) {
      print("❌ Error placing order: $e");
    }
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
        padding:
            EdgeInsets.all(screenWidth * 0.035), // Slightly smaller padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                buildToggleButton('Delivery', true, screenWidth),
                SizedBox(width: screenWidth * 0.015), // Reduced spacing
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
                      fontSize: screenHeight * 0.016, // Reduced size
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
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)), // Reduced
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
                    padding: EdgeInsets.only(
                        left: screenWidth * 0.04), // Adjust padding
                    decoration: BoxDecoration(
                      color: Colors.white, // White background
                      borderRadius:
                          BorderRadius.circular(14), // Rounded corners
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1), // Light shadow
                          offset: Offset(0, 4), // Shadow position
                          blurRadius: 6, // Soft shadow
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
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)), // Reduced
            SizedBox(height: screenHeight * 0.008),
            buildSummaryRow(
                'Subtotal', 'BHD ${widget.subtotal.toStringAsFixed(3)}'),
            buildSummaryRow('Tax', 'BHD ${widget.tax.toStringAsFixed(3)}'),
            Divider(thickness: 1, color: Colors.grey),
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
                    horizontal: screenWidth * 0.35, // Reduced width
                    vertical: screenHeight * 0.018, // Slightly smaller height
                  ),
                  textStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.04), // Reduced size
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
        child: Text(text,
            style: TextStyle(fontSize: screenWidth * 0.035)), // Reduced
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
        child: Text(text,
            style: TextStyle(fontSize: screenWidth * 0.035)), // Reduced
      ),
    );
  }

  Widget buildSummaryRow(String title, String amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5), // Reduced padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: isBold ? 18 : 13)), // Reduced size
          Text(amount,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: isBold ? 18 : 13)), // Reduced size
        ],
      ),
    );
  }
}
