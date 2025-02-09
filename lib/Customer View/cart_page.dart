import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hometouch/Customer%20View/bottom_nav_bar.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final double deliveryCost = 0.500;
  final double taxPercentage = 10 / 100;
  List<Map<String, dynamic>> cartItems = [];
  bool isLoading = true;

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
        data["cartId"] = doc.id; // Store document ID for deletion
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const CircleAvatar(
            backgroundColor: Color(0xFFBF0000),
            child: Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Cart",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
              ? _buildEmptyCart()
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          final addOns = item['addOns'] as List<dynamic>;
                          final basePrice = item['price'] as double;
                          final quantity = item['quantity'] as int;
                          final addOnsCost = addOns.fold(0.0,
                              (sum, addOn) => sum + (addOn['price'] as double));

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['name'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            if (addOns.isNotEmpty)
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children:
                                                    addOns.map<Widget>((addOn) {
                                                  return Text(
                                                    "+ ${addOn['name']} (${addOn['price'].toStringAsFixed(3)} BHD)",
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black54,
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            Text(
                                              "Price: ${(basePrice + addOnsCost).toStringAsFixed(3)} x $quantity",
                                              style: const TextStyle(
                                                color: Colors.black54,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.remove,
                                              color: Color(0xFFBF0000),
                                            ),
                                            onPressed: () {
                                              _updateQuantity(
                                                  item['cartId'], quantity - 1);
                                            },
                                          ),
                                          Text(
                                            "$quantity",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.add,
                                              color: Color(0xFFBF0000),
                                            ),
                                            onPressed: () {
                                              _updateQuantity(
                                                  item['cartId'], quantity + 1);
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Color(0xFFBF0000),
                                            ),
                                            onPressed: () {
                                              _removeItem(item['cartId']);
                                            },
                                          ),
                                        ],
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
                            onPressed: () {},
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
                        ],
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: BottomNavBar(selectedIndex: 2),
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
        Text("${value.toStringAsFixed(3)} BHD"),
      ],
    );
  }
}
