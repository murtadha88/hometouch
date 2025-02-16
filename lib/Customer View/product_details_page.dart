import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hometouch/Customer%20View/review_page.dart';

class ProductDetailsPage extends StatefulWidget {
  final String productId; // Only pass the Product ID

  const ProductDetailsPage({super.key, required this.productId});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  Map<String, dynamic>? productData;
  List<Map<String, dynamic>> addOns = [];
  List<Map<String, dynamic>> removals = [];
  List<Map<String, dynamic>> reviews = [];
  bool isLoading = true;
  int _quantity = 1;
  bool isFavorite = false;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
    _checkFavoriteStatus();
    _fetchRecentReviews();
  }

  Future<void> _fetchProductDetails() async {
    try {
      QuerySnapshot vendorsSnapshot =
          await FirebaseFirestore.instance.collection('vendor').get();

      for (var vendorDoc in vendorsSnapshot.docs) {
        QuerySnapshot categoriesSnapshot = await FirebaseFirestore.instance
            .collection('vendor')
            .doc(vendorDoc.id)
            .collection('category')
            .get();

        for (var categoryDoc in categoriesSnapshot.docs) {
          DocumentSnapshot productDoc = await FirebaseFirestore.instance
              .collection('vendor')
              .doc(vendorDoc.id)
              .collection('category')
              .doc(categoryDoc.id)
              .collection('products')
              .doc(widget.productId)
              .get();

          if (productDoc.exists) {
            print("✅ Product found: ${productDoc.id}");

            setState(() {
              productData = productDoc.data() as Map<String, dynamic>?;
              productData?["vendorId"] = vendorDoc.id; // ✅ Store Vendor ID
              productData?["categoryId"] =
                  categoryDoc.id; // ✅ Store Category ID
              isLoading = false;
            });

            await _fetchAddOnsAndRemovals(vendorDoc.id, categoryDoc.id);
            await _checkFavoriteStatus();
            await _fetchRecentReviews();

            return;
          }
        }
      }

      setState(() {
        isLoading = false; // ✅ Stop loading if product is not found
      });
    } catch (e) {
      print("❌ Error fetching product details: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchAddOnsAndRemovals(
      String vendorId, String categoryId) async {
    try {
      // Fetch Add-Ons
      QuerySnapshot addOnsSnapshot = await FirebaseFirestore.instance
          .collection('vendor')
          .doc(vendorId)
          .collection('category')
          .doc(categoryId)
          .collection('products')
          .doc(widget.productId)
          .collection('Add_Ons')
          .get();

      // Fetch Removals
      QuerySnapshot removalsSnapshot = await FirebaseFirestore.instance
          .collection('vendor')
          .doc(vendorId)
          .collection('category')
          .doc(categoryId)
          .collection('products')
          .doc(widget.productId)
          .collection('Remove')
          .get();

      setState(() {
        addOns = addOnsSnapshot.docs
            .map((doc) =>
                {"name": doc["Name"], "price": doc["Price"], "selected": false})
            .toList();

        removals = removalsSnapshot.docs
            .map((doc) => {"name": doc["Name"], "selected": false})
            .toList();
      });
    } catch (e) {
      print("Error fetching add-ons and removals: $e");
    }
  }

  double get _addOnsTotal {
    return addOns.fold(
      0.0,
      (sum, addOn) =>
          (addOn["selected"] == true ? sum + (addOn["price"] ?? 0.0) : sum),
    );
  }

  double get _totalPrice {
    double basePrice = (productData?["Price"] ?? 0).toDouble();
    return (basePrice + _addOnsTotal) * (_quantity > 0 ? _quantity : 1);
  }

  Future<void> _fetchRecentReviews() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection("review")
          .where("Product_ID", isEqualTo: widget.productId)
          .orderBy("Date", descending: true)
          .limit(3)
          .get();

      if (snapshot.docs.isEmpty) {
        print("No reviews found for Product ID: ${widget.productId}");
        setState(() {
          reviews = [];
        });
        return;
      }

      List<Future<Map<String, dynamic>>> reviewFutures =
          snapshot.docs.map((doc) async {
        var data = doc.data() as Map<String, dynamic>;
        var customerRef = data["Customer_ID"] as DocumentReference;

        try {
          var customerSnapshot = await customerRef.get();
          var customerData = customerSnapshot.data() as Map<String, dynamic>?;

          return {
            "name": customerData?["Name"] ?? "Unknown Customer",
            "photo": customerData?["Photo"] ?? "", // Handle missing images
            "rating": data["Rating"],
            "review": data["Review"],
            "date": (data["Date"] as Timestamp).toDate(),
          };
        } catch (e) {
          print("Error fetching customer details: $e");
          return {
            "name": "Unknown Customer",
            "photo": "",
            "rating": data["Rating"],
            "review": data["Review"],
            "date": (data["Date"] as Timestamp).toDate(),
          };
        }
      }).toList();

      // Wait for all customer data to be fetched before updating the state
      List<Map<String, dynamic>> fetchedReviews =
          await Future.wait(reviewFutures);

      setState(() {
        reviews = fetchedReviews;
      });
    } catch (e) {
      print("Error fetching reviews: $e");
    }
  }

  Future<void> _checkFavoriteStatus() async {
    if (productData?["vendorId"] == null ||
        productData?["categoryId"] == null) {
      print(
          "ERROR: Vendor ID or Category ID is NULL! Cannot check favorite status.");
      return;
    }

    // Get the product reference
    DocumentReference productRef = FirebaseFirestore.instance
        .collection("vendor")
        .doc(productData?["vendorId"])
        .collection("category")
        .doc(productData?["categoryId"])
        .collection("products")
        .doc(widget.productId);

    print("Checking favorite status for: $productRef");

    var favoriteRef = FirebaseFirestore.instance
        .collection("Customer")
        .doc(currentUserId)
        .collection("favorite")
        .where("Type", isEqualTo: "product")
        .where("Product_ID", isEqualTo: productRef); // Compare as reference

    var snapshot = await favoriteRef.get();

    setState(() {
      isFavorite = snapshot.docs.isNotEmpty;
    });

    print("Favorite status: ${isFavorite ? 'YES' : 'NO'}");
  }

  void _toggleFavorite() async {
    var favoriteRef = FirebaseFirestore.instance
        .collection("Customer")
        .doc(currentUserId)
        .collection("favorite");

    if (isFavorite) {
      // Remove from favorites
      var favoriteDoc = await favoriteRef
          .where("Type", isEqualTo: "product")
          .where("Product_ID",
              isEqualTo: FirebaseFirestore.instance
                  .collection("vendor")
                  .doc(productData?["vendorId"])
                  .collection("category")
                  .doc(productData?["categoryId"])
                  .collection("products")
                  .doc(widget.productId)) // Ensure it's a reference
          .get();

      for (var doc in favoriteDoc.docs) {
        await doc.reference.delete();
      }
    } else {
      // Ensure vendor and category IDs exist before adding
      if (productData?["vendorId"] != null &&
          productData?["categoryId"] != null) {
        DocumentReference productRef = FirebaseFirestore.instance
            .collection("vendor")
            .doc(productData?["vendorId"])
            .collection("category")
            .doc(productData?["categoryId"])
            .collection("products")
            .doc(widget.productId);

        await favoriteRef.add({
          "Type": "product",
          "Product_ID": productRef, // Store as Firestore reference
        });
      }
    }

    setState(() {
      isFavorite = !isFavorite;
    });
  }

  Future<void> _addToCart() async {
    if (productData == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final cartRef = FirebaseFirestore.instance
          .collection('Customer')
          .doc(user.uid)
          .collection('cart');

      List<Map<String, dynamic>> selectedAddOns =
          addOns.where((addOn) => addOn["selected"] == true).toList();

      Map<String, dynamic> cartItem = {
        "productId": widget.productId,
        "name": productData?["Name"] ?? "Unknown",
        "price": productData?["Price"] ?? 0,
        "quantity": _quantity,
        "addOns": selectedAddOns,
        "vendorId": productData?["vendorId"],
        "image": productData?["Image"],
      };

      await cartRef.add(cartItem);

      Navigator.pop(context);
    } catch (e) {
      print("Error adding to cart: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || productData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(screenHeight * 0.09),
        child: AppBar(
          backgroundColor: Colors.white,
          leading: Padding(
            padding: EdgeInsets.only(
              top: screenHeight * 0.025,
              left: screenWidth * 0.02,
            ),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFBF0000),
                ),
                alignment: Alignment.center,
                padding: EdgeInsets.only(
                  top: screenHeight * 0.001,
                  left: screenWidth * 0.02,
                ),
                child: Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: screenHeight * 0.025, // Match second AppBar size
                ),
              ),
            ),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(
                  top: screenHeight * 0.02, right: screenWidth * 0.02),
              child: GestureDetector(
                onTap: _toggleFavorite, // ✅ Handle tap
                child: CircleAvatar(
                  backgroundColor: const Color(0xFFBF0000),
                  radius: screenHeight * 0.027, // Match second AppBar icon size
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: Colors.white,
                    size: screenHeight * 0.027, // Keep same size as other icons
                  ),
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(screenHeight * 0.002),
            child: Divider(
              thickness: screenHeight * 0.001,
              color: Colors.grey[300],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05, vertical: screenHeight * 0.02),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: screenHeight * 0.25,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(screenWidth * 0.04),
                image: DecorationImage(
                  image: NetworkImage(productData?["Image"] ?? ""),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.01),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Product Name + Rating in the red box
                Row(
                  children: [
                    // Product Name
                    Text(
                      productData?["Name"] ?? "Unknown Product",
                      style: TextStyle(
                        fontSize: screenWidth * 0.07,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(width: screenWidth * 0.03),

                    // Star Icon + Rating Number
                    Row(
                      children: [
                        Icon(Icons.star,
                            color: Color(0xFFBF0000),
                            size: screenWidth * 0.065),
                        SizedBox(width: 2),
                        Text(
                          (productData?["Rating"] ?? 0.0).toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: screenWidth * 0.065,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Review Icon Button (on the far right)
                IconButton(
                  icon: CircleAvatar(
                    backgroundColor: const Color(0xFFBF0000),
                    child: Icon(Icons.rate_review,
                        color: Colors.white, size: screenHeight * 0.03),
                  ),
                  onPressed: () {
                    if (productData?["categoryId"] == null) {
                      print(
                          "ERROR: categoryId is required to rate this product.");
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReviewPage(
                          productId: widget.productId,
                          categoryId: productData?["categoryId"],
                        ),
                      ),
                    ).then((_) {
                      _fetchRecentReviews();
                      _fetchProductDetails();
                    });
                  },
                ),
              ],
            ),

            Text(
              "${productData?["Price"].toStringAsFixed(3)} BHD",
              style: TextStyle(
                fontSize: screenWidth * 0.06,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFBF0000),
              ),
            ),
            SizedBox(height: screenHeight * 0.01),

            Text(
              productData?["Description"] ?? "No description available.",
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: Colors.black54,
                height: 1.6,
              ),
            ),
            SizedBox(height: screenHeight * 0.03),

            // Add-Ons
            _buildSectionTitle("Add-Ons", screenWidth),
            _buildAddOns(),
            SizedBox(height: screenHeight * 0.02),

            // Removals
            _buildSectionTitle("Remove", screenWidth),
            _buildRemovals(),
            SizedBox(height: screenHeight * 0.02),

            // Reviews Section
            _buildSectionTitle("Reviews", screenWidth),
            _buildReviews(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
            left: screenWidth * 0.04, right: screenWidth * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          border:
              Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quantity Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Quantity",
                    style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove,
                          color: const Color(0xFFBF0000),
                          size: screenWidth * 0.07),
                      onPressed: () {
                        setState(() {
                          if (_quantity > 1) _quantity--;
                        });
                      },
                    ),
                    Text(
                      _quantity.toString(),
                      style: TextStyle(
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.add,
                          color: const Color(0xFFBF0000),
                          size: screenWidth * 0.07),
                      onPressed: () {
                        setState(() {
                          _quantity++;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            // SizedBox(height: screenHeight * 0.01),

            // Add to Cart Button
            ElevatedButton(
              onPressed: _addToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBF0000),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.08)),
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
              ),
              child: Center(
                child: Text(
                  "Add to Cart (${_totalPrice.toStringAsFixed(3)} BHD)",
                  style: TextStyle(
                      fontSize: screenWidth * 0.05, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, double screenWidth) {
    return Text(
      title,
      style:
          TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildReviews() {
    if (reviews.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.white,
        ),
        child: Row(
          children: [
            const Icon(Icons.sentiment_dissatisfied,
                color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            const Text(
              "No reviews yet.",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      );
    }

    return Column(
      children: reviews.map((review) {
        String? userPhotoBase64 =
            review["photo"] == "" ? null : review["photo"];
        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: userPhotoBase64 != null
                    ? MemoryImage(base64Decode(userPhotoBase64))
                    : const NetworkImage('https://i.imgur.com/OtAn7hT.jpeg')
                        as ImageProvider,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review["name"],
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < review["rating"]
                              ? Icons.star
                              : Icons.star_border,
                          color: Color(0xFFBF0000),
                          size: 18,
                        );
                      }),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      review["review"],
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAddOns() {
    return Column(
      children: addOns.map((addOn) {
        return CheckboxListTile(
          title: Text(addOn["name"]),
          subtitle: Text("+${addOn["price"].toStringAsFixed(3)} BHD"),
          value: addOn["selected"],
          onChanged: (bool? value) {
            setState(() {
              addOn["selected"] = value!;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: const Color(0xFFBF0000),
          checkColor: Colors.white,
        );
      }).toList(),
    );
  }

  Widget _buildRemovals() {
    return Column(
      children: removals.map((removal) {
        return CheckboxListTile(
          title: Text(removal["name"]),
          value: removal["selected"],
          onChanged: (bool? value) {
            setState(() {
              removal["selected"] = value!;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: const Color(0xFFBF0000), // Red background when selected
          checkColor: Colors.white, // White tick when selected
        );
      }).toList(),
    );
  }
}
