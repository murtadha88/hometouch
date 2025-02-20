import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hometouch/Customer%20View/address_dialog.dart';
import 'package:hometouch/Customer%20View/bottom_nav_bar.dart';
import 'package:hometouch/Customer%20View/checkout_page.dart';

class CartPage extends StatefulWidget {
  final bool isFromNavBar;

  const CartPage({
    super.key,
    this.isFromNavBar = false,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final double deliveryCost = 0.500;
  final double taxPercentage = 10 / 100;
  List<Map<String, dynamic>> cartItems = [];
  bool isLoading = true;
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  Future<void> _fetchCartItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final cartSnapshot = await FirebaseFirestore.instance
          .collection('Customer')
          .doc(user.uid)
          .collection('cart')
          .get();

      List<Map<String, dynamic>> items = cartSnapshot.docs.map((doc) {
        var data = doc.data();
        data["cartId"] = doc.id;
        return data;
      }).toList();

      setState(() {
        cartItems = items;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error fetching cart items: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  double get subtotal => cartItems.fold(
        0.0,
        (sum, item) {
          double basePrice = item['price'] as double;
          int quantity = item['quantity'] as int;
          double addOnsCost = (item['addOns'] as List<dynamic>)
              .fold(0.0, (sum, addOn) => sum + (addOn['price'] as double));
          return sum + (basePrice + addOnsCost) * quantity;
        },
      );

  double get tax => subtotal * taxPercentage;
  double get total => subtotal + deliveryCost + tax;

  Future<void> _updateQuantity(String cartId, int newQuantity) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (newQuantity <= 0) {
      _removeItem(cartId);
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('Customer')
          .doc(user.uid)
          .collection('cart')
          .doc(cartId)
          .update({"quantity": newQuantity});

      _fetchCartItems();
    } catch (e) {
      print("❌ Error updating quantity: $e");
    }
  }

  Future<void> _removeItem(String cartId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('Customer')
          .doc(user.uid)
          .collection('cart')
          .doc(cartId)
          .delete();

      _fetchCartItems();
    } catch (e) {
      print("❌ Error removing item: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () async {
        return !widget.isFromNavBar;
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(screenHeight * 0.09),
          child: AppBar(
            leading: widget.isFromNavBar
                ? SizedBox()
                : Padding(
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
                            top: screenHeight * 0.001,
                            left: screenWidth * 0.02),
                        child: Icon(Icons.arrow_back_ios,
                            color: Colors.white, size: screenHeight * 0.025),
                      ),
                    ),
                  ),
            title: Padding(
              padding: EdgeInsets.only(top: screenHeight * 0.02),
              child: Text(
                'Cart',
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
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFBF0000)))
            : cartItems.isEmpty
                ? _buildEmptyCart()
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.03,
                            vertical: screenHeight * 0.01,
                          ),
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) {
                            final item = cartItems[index];
                            final addOns = item['addOns'] as List<dynamic>;
                            final basePrice = item['price'] as double;
                            final quantity = item['quantity'] as int;
                            final addOnsCost = addOns.fold(
                              0.0,
                              (sum, addOn) => sum + (addOn['price'] as double),
                            );

                            return Card(
                              margin:
                                  EdgeInsets.only(bottom: screenHeight * 0.01),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(screenWidth * 0.03),
                              ),
                              color: Colors.white,
                              child: Padding(
                                padding: EdgeInsets.all(screenWidth * 0.03),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: screenWidth * 0.18,
                                      height: screenHeight * 0.09,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                            screenWidth * 0.02),
                                        image: DecorationImage(
                                          image: (item['image'] != null &&
                                                  item['image']
                                                      .toString()
                                                      .isNotEmpty)
                                              ? NetworkImage(item['image'])
                                              : const AssetImage(
                                                      'assets/placeholder_image.jpg')
                                                  as ImageProvider,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.03),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['name'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: screenWidth * 0.04,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(
                                              height: screenHeight * 0.005),
                                          if (addOns.isNotEmpty)
                                            ...addOns.map<Widget>((addOn) {
                                              return Text(
                                                "+ ${addOn['name']} "
                                                "(${(addOn['price'] as double).toStringAsFixed(3)} BHD)",
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.035,
                                                  color: Colors.black54,
                                                ),
                                              );
                                            }).toList(),
                                          SizedBox(
                                              height: screenHeight * 0.005),
                                          Text(
                                            "Price: ${(basePrice + addOnsCost).toStringAsFixed(3)} x $quantity",
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.035,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: Icon(
                                            Icons.add,
                                            color: const Color(0xFFBF0000),
                                            size: screenWidth * 0.06,
                                          ),
                                          onPressed: () {
                                            _updateQuantity(
                                                item['cartId'], quantity + 1);
                                          },
                                        ),
                                        Text(
                                          "$quantity",
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.04,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: Icon(
                                            Icons.remove,
                                            color: const Color(0xFFBF0000),
                                            size: screenWidth * 0.06,
                                          ),
                                          onPressed: () {
                                            _updateQuantity(
                                                item['cartId'], quantity - 1);
                                            if (quantity == 0) {
                                              _removeItem(item['cartId']);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSummaryRow("Subtotal", subtotal),
                            _buildSummaryRow("Delivery Cost", deliveryCost),
                            _buildSummaryRow("Tax", tax),
                            const Divider(),
                            _buildSummaryRow("Total", total, isBold: true),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () async {
                                final selectedAddress =
                                    await showModalBottomSheet<Address?>(
                                  context: context,
                                  builder: (context) => AddressDialog(
                                    screenWidth: screenWidth,
                                    screenHeight: screenHeight,
                                    onClose: () => Navigator.pop(context),
                                  ),
                                );

                                if (selectedAddress != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CheckoutPage(
                                        cartItems: cartItems,
                                        subtotal: subtotal,
                                        tax: tax,
                                        total: total,
                                        selectedAddress: selectedAddress,
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFBF0000),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.all(16),
                              ),
                              child: const Text(
                                "Checkout",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 25),
                          ],
                        ),
                      ),
                    ],
                  ),
        bottomNavigationBar: BottomNavBar(selectedIndex: 2),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const CartPage()),
                  );
                },
                backgroundColor: const Color(0xFFBF0000),
                shape: const CircleBorder(),
                elevation: 5,
                child: const Icon(Icons.shopping_cart,
                    color: Colors.white, size: 30),
              ),
            ),
            if (_selectedIndex == 2) ...[
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: 1.0,
                child: Text(
                  "Cart",
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFBF0000),
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget _buildEmptyCart() {
    return const Center(child: Text("Your cart is empty"));
  }

  Widget _buildSummaryRow(String label, double value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text("${value.toStringAsFixed(3)} BHD",
            style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}
