import 'package:flutter/material.dart';

class CartPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  const CartPage({super.key, required this.cartItems});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final double deliveryCost = 0.500;
  final double taxPercentage = 10 / 100;

  double get subtotal => widget.cartItems.fold(
        0.0,
        (sum, item) {
          double basePrice = item['price'] as double;
          int quantity = item['quantity'] as int;
          double addOnsCost = (item['addOns'] as List<dynamic>)
              .fold(0.0, (sum, addOn) => sum + addOn['price']);
          return sum + (basePrice + addOnsCost) * quantity;
        },
      );

  double get tax => subtotal * taxPercentage;

  double get total => subtotal + deliveryCost + tax;

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
      body: widget.cartItems.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: widget.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = widget.cartItems[index];
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
                                  // Item Details
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
                                        // Add-ons displayed under item
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
                                  // Quantity Control and Delete Button
                                  Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.black26,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.remove,
                                                size: 20,
                                                color: Color(0xFFBF0000),
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  if (item['quantity'] > 1) {
                                                    item['quantity'] -= 1;
                                                  } else {
                                                    _showDeleteConfirmationDialog(
                                                        context, index);
                                                  }
                                                });
                                              },
                                            ),
                                            Text(
                                              item['quantity'].toString(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.add,
                                                size: 20,
                                                color: Color(0xFFBF0000),
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  item['quantity'] += 1;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Color(0xFFBF0000),
                                          size: 24,
                                        ),
                                        onPressed: () {
                                          _showDeleteConfirmationDialog(
                                              context, index);
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
                // Pricing Summary
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSummaryRow("Subtotal", subtotal),
                      _buildSummaryRow("Delivery Cost", deliveryCost),
                      _buildSummaryRow("Tax", tax),
                      const Divider(thickness: 1, height: 32),
                      _buildSummaryRow(
                        "Total Amount",
                        total,
                        isBold: true,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Logic for Checkout
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBF0000),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Center(
                          child: Text(
                            "Checkout",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 200,
              width: 200,
              color: Colors.grey[300], // Placeholder for the image
              child: const Icon(
                Icons.image,
                size: 100,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Oops, Your cart is empty!",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Seems like you have not ordered any food yet",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Logic to go back
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBF0000),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              ),
              child: const Text(
                "Go Back",
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
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Center(
            child: Text(
              "Delete Item",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          content: const Text(
            "Are you sure you want to remove this item from your cart?",
            textAlign: TextAlign.center,
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBF0000),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      widget.cartItems.removeAt(index);
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "YES",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFFBF0000),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "NO",
                    style: TextStyle(color: Color(0xFFBF0000)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            "${value.toStringAsFixed(3)} BHD",
            style: TextStyle(
              fontSize: 14,
              color: isBold ? Colors.black : Colors.black54,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
