import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hometouch/Customer%20View/home_page.dart';
import 'package:hometouch/Customer%20View/order_history_page.dart';
import 'package:intl/intl.dart';
import 'package:hometouch/Customer View/address_dialog.dart';
import 'dart:async';
import 'dart:math' as math;

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double subtotal;
  final double tax;
  final double deliveryCost;
  final int totalPoints;
  final double total;
  final Address selectedAddress;

  const CheckoutPage({
    super.key,
    required this.cartItems,
    required this.subtotal,
    required this.deliveryCost,
    required this.tax,
    required this.totalPoints,
    required this.total,
    required this.selectedAddress,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int selectedPaymentMethod = 0;
  bool? useDelivery;
  bool? selectedTime;
  DateTime? scheduleTime;
  String? selectedCoupon;
  double discount = 0.0;
  TextEditingController couponController = TextEditingController();
  bool requireSubscription = false;
  String hitText = "";
  Timer? timer;

  double vendorRevenue = 0;
  double homeTouchCut = 0;
  double roundedVendorRevenue = 0;

  double finalDeliveryCost = 0.0;

  @override
  void initState() {
    super.initState();
    _checkSubscriptionVoucher();
    _calculateDeliveryCost();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _checkSubscriptionVoucher() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    QuerySnapshot subscriptionSnapshot = await FirebaseFirestore.instance
        .collection('subscription')
        .where('Customer_ID',
            isEqualTo:
                FirebaseFirestore.instance.collection('Customer').doc(user.uid))
        .get();

    if (subscriptionSnapshot.docs.isNotEmpty) {
      var subscriptionData =
          subscriptionSnapshot.docs.first.data() as Map<String, dynamic>;
      Timestamp startDate = subscriptionData["Start_Date"];
      Timestamp endDate = subscriptionData["End_Date"];
      int voucherNo = subscriptionData["Voucher_No"] ?? 0;

      DateTime now = DateTime.now();
      if (now.isAfter(startDate.toDate()) && now.isBefore(endDate.toDate())) {
        setState(() {
          voucherNo > 0
              ? (requireSubscription = false, hitText = "Select a coupon")
              : (
                  requireSubscription = true,
                  hitText = "You dont have a coupon"
                );
        });
      } else {
        setState(() {
          requireSubscription = true;
          hitText = "Requires Subscription";
        });
      }
    } else {
      setState(() {
        requireSubscription = true;
        hitText = "Requires Subscription";
      });
    }
  }

  Future<void> _calculateDeliveryCost() async {
    if (widget.cartItems.isNotEmpty) {
      String vendorId = widget.cartItems.first["vendorId"].toString();
      DocumentSnapshot vendorSnapshot = await FirebaseFirestore.instance
          .collection('vendor')
          .doc(vendorId)
          .get();

      if (vendorSnapshot.exists && vendorSnapshot.get('Location') != null) {
        GeoPoint vendorLocation = vendorSnapshot.get('Location') as GeoPoint;
        GeoPoint customerLocation = widget.selectedAddress.location;
        double distance = calculateDistance(vendorLocation, customerLocation);

        double cost = 0.0;
        if (distance <= 5) {
          cost = 0.4;
        } else {
          double extraDistance = distance - 5;
          int extraUnits = (extraDistance / 3).ceil();
          cost = 0.4 + extraUnits * 0.1;
        }
        setState(() {
          finalDeliveryCost = cost;
        });
      }
    }
  }

  double calculateDistance(GeoPoint pos1, GeoPoint pos2) {
    const double earthRadius = 6371;
    double lat1 = pos1.latitude * (math.pi / 180);
    double lon1 = pos1.longitude * (math.pi / 180);
    double lat2 = pos2.latitude * (math.pi / 180);
    double lon2 = pos2.longitude * (math.pi / 180);
    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  Future<int> _getNextOrderNumber() async {
    final orderCollection = FirebaseFirestore.instance.collection('order');
    final querySnapshot = await orderCollection.get();

    int maxOrderNumber = 0;
    for (var doc in querySnapshot.docs) {
      String orderNumberStr = doc.get("Order_Number") as String;
      orderNumberStr = orderNumberStr.substring(1);

      int orderNumberInt = int.tryParse(orderNumberStr) ?? 0;
      if (orderNumberInt > maxOrderNumber) {
        maxOrderNumber = orderNumberInt;
      }
    }
    return maxOrderNumber + 1;
  }

  Future<void> _placeOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      int orderNumber = await _getNextOrderNumber();

      String vendorId = widget.cartItems.isNotEmpty
          ? widget.cartItems.first["vendorId"].toString()
          : "Unknown";

      DocumentSnapshot vendorSnapshot = await FirebaseFirestore.instance
          .collection('vendor')
          .doc(vendorId)
          .get();

      if (!vendorSnapshot.exists) {
        print("Vendor not found");
        return;
      }

      GeoPoint vendorLocation;
      if (vendorSnapshot.get('Location') != null) {
        vendorLocation = vendorSnapshot.get('Location') as GeoPoint;
      } else {
        print("Vendor location not available");
        return;
      }

      QuerySnapshot driversSnapshot = await FirebaseFirestore.instance
          .collection('Driver')
          .where('isBusy', isEqualTo: false)
          .get();

      List<QueryDocumentSnapshot> drivers = driversSnapshot.docs;

      String? nearestDriverId;
      double minDistance = double.infinity;

      for (var driverDoc in drivers) {
        GeoPoint? driverGeoPoint = driverDoc.get('Location') as GeoPoint?;
        if (driverGeoPoint == null) continue;

        double distance = calculateDistance(vendorLocation, driverGeoPoint);
        if (distance < minDistance) {
          minDistance = distance;
          nearestDriverId = driverDoc.id;
        }
      }

      if (nearestDriverId == null) {
        print("No available drivers nearby");
        nearestDriverId = "Pending";
      }

      homeTouchCut = widget.subtotal * 0.15;
      vendorRevenue = widget.subtotal - homeTouchCut;
      roundedVendorRevenue = double.parse(vendorRevenue.toStringAsFixed(3));
      double roundedTotal = double.parse(widget.total.toStringAsFixed(3));
      double roundedSubTotal = double.parse(widget.subtotal.toStringAsFixed(3));

      DocumentReference orderRef =
          FirebaseFirestore.instance.collection('order').doc("#$orderNumber");

      await orderRef.set({
        "Order_Number": "#$orderNumber",
        "Customer_ID": user.uid,
        "Driver_ID": nearestDriverId,
        "Vendor_ID": vendorId,
        "Items": widget.cartItems,
        "Subtotal": roundedSubTotal,
        "Total": roundedTotal,
        "Total_Vendor_Revenue": vendorRevenue,
        "Total_Points_Used": widget.totalPoints,
        "Total_HomeTouch_Revenue": homeTouchCut,
        "Payment_Method": selectedPaymentMethod == 0
            ? "Card"
            : selectedPaymentMethod == 1
                ? "Benefit Pay"
                : "Cash",
        "Delivery_Type": useDelivery == true ? "Delivery" : "Pickup",
        "Deilvery_Cost": finalDeliveryCost,
        "Time": selectedTime == true ? "Now" : "Scheduled",
        "Schedule_Time":
            scheduleTime != null ? Timestamp.fromDate(scheduleTime!) : null,
        "Status": "Preparing",
        "Order_Date": FieldValue.serverTimestamp(),
        "Accepted": null,
        "Customer_Address": {
          "Name": widget.selectedAddress.name,
          "Building": widget.selectedAddress.building,
          "Road": widget.selectedAddress.road,
          "Block": widget.selectedAddress.block,
          "Floor": widget.selectedAddress.floor,
          "Apartment": widget.selectedAddress.apartment,
          "Office": widget.selectedAddress.office,
          "Company_Name": widget.selectedAddress.companyName,
          "Location": widget.selectedAddress.location,
        }
      });

      _waitForOrderAcceptance(orderRef.id, vendorId, nearestDriverId);
    } catch (e) {
      print("Error placing order: $e");
    }
  }

  Future<void> _waitForOrderAcceptance(
      String orderId, String vendorId, String nearestDriverId) async {
    int secondsRemaining = 300;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            timer ??= Timer.periodic(Duration(seconds: 1), (t) async {
              if (!mounted) {
                t.cancel();
                return;
              }

              DocumentSnapshot orderSnapshot = await FirebaseFirestore.instance
                  .collection("order")
                  .doc(orderId)
                  .get();

              if (!orderSnapshot.exists) {
                t.cancel();
                Navigator.pop(context);
                return;
              }

              dynamic acceptedStatus = orderSnapshot["Accepted"];
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;

              if (acceptedStatus == true) {
                print("Order accepted");
                t.cancel();
                Navigator.pop(context);
                _clearCart(user.uid);

                await FirebaseFirestore.instance
                    .collection('Customer')
                    .doc(user.uid)
                    .update({
                  'Loyalty_Points': FieldValue.increment(100),
                });

                final vendorRef = FirebaseFirestore.instance
                    .collection('vendor')
                    .doc(vendorId);
                await vendorRef.update({
                  'Total_Orders': FieldValue.increment(1),
                  'Total_Revenue': FieldValue.increment(roundedVendorRevenue),
                });

                final now = DateTime.now();
                final firstDayOfMonth = DateTime(now.year, now.month, 1);
                final monthlySalesRef = vendorRef
                    .collection('Monthly_Sales')
                    .doc(DateFormat('yyyy-MM').format(firstDayOfMonth));

                await monthlySalesRef.set({
                  'Orders': FieldValue.increment(1),
                  'Sales': FieldValue.increment(roundedVendorRevenue),
                  'Month': now.month.toString(),
                  'Year': now.year.toString(),
                  'Date': Timestamp.fromDate(firstDayOfMonth),
                }, SetOptions(merge: true));

                final today = DateTime(now.year, now.month, now.day);
                final salesDataRef = vendorRef
                    .collection('Sales_Data')
                    .doc(DateFormat('yyyy-MM-dd').format(today));

                await salesDataRef.set({
                  'Orders': FieldValue.increment(1),
                  'Sales': FieldValue.increment(roundedVendorRevenue),
                  'Day': now.day.toString(),
                  'Label': DateFormat('E').format(now),
                  'Date': Timestamp.fromDate(today),
                }, SetOptions(merge: true));

                if (nearestDriverId != "Pending") {
                  final driverRef = FirebaseFirestore.instance
                      .collection('Driver')
                      .doc(nearestDriverId);

                  await driverRef.update({
                    'Total_Orders': FieldValue.increment(1),
                    'Total_Revenue': FieldValue.increment(finalDeliveryCost),
                    'isBusy': true,
                  });

                  final driverSalesDataRef = driverRef
                      .collection('Sales_Data')
                      .doc(DateFormat('yyyy-MM-dd').format(DateTime.now()));

                  await driverSalesDataRef.set({
                    'Orders': FieldValue.increment(1),
                    'Revenue': FieldValue.increment(finalDeliveryCost),
                    'Day': DateFormat('d').format(DateTime.now()),
                    'Label': DateFormat('E').format(DateTime.now()),
                    'Date': Timestamp.now(),
                  }, SetOptions(merge: true));
                }

                _showSuccessDialog();

                return;
              }

              if (acceptedStatus == false) {
                print("Order rejected");
                t.cancel();
                Navigator.pop(context);
                _clearCart(user.uid);

                await FirebaseFirestore.instance
                    .collection("order")
                    .doc(orderId)
                    .update({"Status": "Rejected"});

                _showFailedDialog();
                return;
              }

              if (secondsRemaining <= 0) {
                print("Order not accepted in time");
                t.cancel();
                Navigator.pop(context);
                _clearCart(user.uid);

                await FirebaseFirestore.instance
                    .collection("order")
                    .doc(orderId)
                    .update({"Status": "Cancelled"});

                _showFailedDialog();
                return;
              } else {
                setState(() {
                  secondsRemaining -= 1;
                });
              }
            });

            double progressValue = 1 - (secondsRemaining / 300);

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 70),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Order Acceptance",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              timer?.cancel();
                              timer = null;
                              Navigator.pop(context);

                              await FirebaseFirestore.instance
                                  .collection("order")
                                  .doc(orderId)
                                  .delete();
                            },
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFBF0000),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 25, top: 25),
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.scale(
                              scale: 4,
                              child: CircularProgressIndicator(
                                value: progressValue,
                                strokeWidth: 6,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFBF0000),
                                ),
                                backgroundColor: Colors.grey.shade300,
                              ),
                            ),
                            Text(
                              "${(secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(secondsRemaining % 60).toString().padLeft(2, '0')}",
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFBF0000),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 75),
                      child: Text(
                        "Waiting for vendor to accept your order...",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      timer?.cancel();
      timer = null;
    });
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
    } catch (e) {
      print("Error clearing cart: $e");
    }
  }

  Future<void> _showSuccessDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        Future.delayed(const Duration(seconds: 3), () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => OrdersPage()),
            (route) => false,
          );
        });
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

  Future<void> _showFailedDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 3), () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => HomeTouchScreen()),
            (route) => false,
          );
        });
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
              Icons.close,
              color: Colors.white,
              size: screenWidth * 0.12,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Order Rejected',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFBF0000),
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Container(
                alignment: Alignment.center,
                child: Text(
                  'Your order was not accepted. You will be redirected to the home page.',
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

  Future<void> _showCouponBottomSheet() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      QuerySnapshot subscriptionSnapshot = await FirebaseFirestore.instance
          .collection('subscription')
          .where('Customer_ID',
              isEqualTo: FirebaseFirestore.instance
                  .collection('Customer')
                  .doc(user.uid))
          .get();

      if (subscriptionSnapshot.docs.isEmpty) {
        print("No subscription found");
        return;
      }

      var subscriptionData =
          subscriptionSnapshot.docs.first.data() as Map<String, dynamic>;

      Timestamp startDate = subscriptionData["Start_Date"];
      Timestamp endDate = subscriptionData["End_Date"];
      DateTime now = DateTime.now();

      if (!(now.isAfter(startDate.toDate()) &&
          now.isBefore(endDate.toDate()))) {
        return;
      }

      QuerySnapshot couponSnapshot =
          await FirebaseFirestore.instance.collection('coupon').get();

      if (couponSnapshot.docs.isEmpty) {
        return;
      }

      List<Map<String, dynamic>> coupons = couponSnapshot.docs
          .map((doc) => {
                "id": doc.id,
                "name": doc["Name"],
                "percentage": doc["Percentage"],
                "endDate": doc["End_Date"],
              })
          .toList();

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(55),
                topRight: Radius.circular(55),
              ),
              border: Border(
                top: BorderSide(color: Color(0xFFBF0000), width: 4),
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.05,
              vertical: MediaQuery.of(context).size.height * 0.03,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Text(
                    "Available Coupons",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFBF0000),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                ...coupons.map((coupon) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          offset: Offset(0, 4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              coupon["name"],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            Text(
                              "${coupon["percentage"]}% Discount",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedCoupon = coupon["name"];
                              couponController.text = selectedCoupon!;
                              discount = (widget.subtotal *
                                  coupon["percentage"] /
                                  100);
                              discount = (discount * 1000).ceil() / 1000;
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFBF0000),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Apply",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 10),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print("Error fetching coupons: $e");
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

    double subtotalAfterDiscount = widget.subtotal - discount;

    double totalAfterDiscount = subtotalAfterDiscount +
        ((useDelivery ?? false) ? finalDeliveryCost : 0.0);

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
                0, 'Card', null, Icons.credit_card, screenWidth),
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
                      controller: couponController,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: hitText,
                        hintStyle: TextStyle(
                          color: requireSubscription
                              ? Color(0xFFBF0000)
                              : Colors.grey,
                        ),
                        border: InputBorder.none,
                        suffixIcon: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: requireSubscription
                                ? Colors.grey
                                : Color(0xFFBF0000),
                          ),
                          child: IconButton(
                            onPressed: requireSubscription
                                ? null
                                : () {
                                    _showCouponBottomSheet();
                                  },
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
            if (discount > 0)
              buildSummaryRow(
                "Discount",
                "-BHD ${discount.toStringAsFixed(3)}",
                isPoints: true,
              ),
            buildSummaryRow(
              'Delivery Cost',
              (useDelivery ?? false)
                  ? 'BHD ${finalDeliveryCost.toStringAsFixed(3)}'
                  : 'BHD 0.000',
            ),
            Divider(thickness: 1, color: Colors.grey),
            buildSummaryRow('Total Points', 'Points ${widget.totalPoints}',
                isBold: true, isPoints: true),
            buildSummaryRow(
              'Total Amount',
              'BHD ${totalAfterDiscount.toStringAsFixed(3)}',
              isBold: true,
            ),
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
