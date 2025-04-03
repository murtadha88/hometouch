import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hometouch/Common%20Pages/review_page.dart';

class ProductDetailsPage extends StatefulWidget {
  final String productId;
  final bool isFromRewards;
  final int points;
  final bool isVendorView;

  const ProductDetailsPage({
    super.key,
    required this.productId,
    this.isFromRewards = false,
    this.points = 0,
    this.isVendorView = false,
  });

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
              productData?["vendorId"] = vendorDoc.id;
              productData?["categoryId"] = categoryDoc.id;
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
        isLoading = false;
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
      QuerySnapshot addOnsSnapshot = await FirebaseFirestore.instance
          .collection('vendor')
          .doc(vendorId)
          .collection('category')
          .doc(categoryId)
          .collection('products')
          .doc(widget.productId)
          .collection('Add_Ons')
          .get();

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

  String get _totalDisplay {
    if (widget.isFromRewards) {
      return "${(widget.points * _quantity)} Points";
    } else {
      double basePrice = (productData?["Price"] ?? 0).toDouble();
      double totalPrice =
          (basePrice + _addOnsTotal) * (_quantity > 0 ? _quantity : 1);
      return "${totalPrice.toStringAsFixed(3)} BHD";
    }
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
            "photo": customerData?["Photo"] ?? "",
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
        .where("Product_ID", isEqualTo: productRef);

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
      var favoriteDoc = await favoriteRef
          .where("Type", isEqualTo: "product")
          .where("Product_ID",
              isEqualTo: FirebaseFirestore.instance
                  .collection("vendor")
                  .doc(productData?["vendorId"])
                  .collection("category")
                  .doc(productData?["categoryId"])
                  .collection("products")
                  .doc(widget.productId))
          .get();

      for (var doc in favoriteDoc.docs) {
        await doc.reference.delete();
      }
    } else {
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
          "Product_ID": productRef,
          "Vendor_ID": productData?["vendorId"],
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
        "price": widget.isFromRewards ? 0 : (productData?["Price"]) ?? 0,
        "points":
            widget.isFromRewards ? (productData?["Points"] ?? 0).toInt() : 0,
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
                  size: screenHeight * 0.025,
                ),
              ),
            ),
          ),
          actions: [
            if (!widget.isVendorView)
              Padding(
                padding: EdgeInsets.only(
                    top: screenHeight * 0.02, right: screenWidth * 0.02),
                child: GestureDetector(
                  onTap: _toggleFavorite,
                  child: CircleAvatar(
                    backgroundColor: const Color(0xFFBF0000),
                    radius: screenHeight * 0.027,
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.white,
                      size: screenHeight * 0.027,
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
              ),
              child: (productData?['Image'] is String &&
                      (productData?['Image'] as String).isNotEmpty)
                  ? Image.network(
                      productData?['Image'] as String,
                      width: double.infinity,
                      height: screenHeight * 0.25,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                        child:
                            Icon(Icons.fastfood, size: 100, color: Colors.grey),
                      ),
                    )
                  : const Center(
                      child:
                          Icon(Icons.fastfood, size: 100, color: Colors.grey),
                    ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: _buildProductNameSpans(
                              productData?["Name"] ?? "Unknown Product"),
                        ),
                        style: TextStyle(
                          fontSize: screenWidth * 0.07,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: screenHeight * 0.01),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star,
                          color: Color(0xFFBF0000),
                        ),
                        SizedBox(width: 4),
                        Text(
                          (productData?["Rating"] ?? 0.0).toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: screenWidth * 0.065,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        IconButton(
                          icon: CircleAvatar(
                            backgroundColor: Color(0xFFBF0000),
                            child: Icon(Icons.rate_review, color: Colors.white),
                          ),
                          onPressed: () {
                            if (productData?["categoryId"] == null) {
                              print(
                                  "ERROR: categoryId is required to rate this product.");
                              return;
                            }

                            widget.isVendorView
                                ? Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ReviewPage(
                                        productId: widget.productId,
                                        categoryId: productData?["categoryId"],
                                        isVendor: true,
                                      ),
                                    ),
                                  ).then((_) {
                                    _fetchRecentReviews();
                                    _fetchProductDetails();
                                  })
                                : Navigator.push(
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
                  ],
                ),
              ],
            ),
            widget.isFromRewards
                ? Text(
                    "${widget.points.toStringAsFixed(0)} Points Required",
                    style: TextStyle(
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFBF0000),
                    ),
                  )
                : _buildPriceDisplay({
                    "price": productData?["Price"],
                    "Discount_Price": productData?["Discount_Price"],
                    "Discount_Start_Date": productData?["Discount_Start_Date"],
                    "Discount_End_Date": productData?["Discount_End_Date"],
                  }),
            SizedBox(height: screenHeight * 0.02),
            Text(
              productData?["Description"] ?? "No description available.",
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: Colors.black54,
                height: 1.6,
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            _buildSectionTitle("Add-Ons", screenWidth),
            _buildAddOns(),
            SizedBox(height: screenHeight * 0.02),
            _buildSectionTitle("Remove", screenWidth),
            _buildRemovals(),
            SizedBox(height: screenHeight * 0.02),
            _buildSectionTitle("Reviews", screenWidth),
            _buildReviews(),
          ],
        ),
      ),
      bottomNavigationBar: widget.isVendorView
          ? null
          : Container(
              padding: EdgeInsets.only(
                  left: screenWidth * 0.04, right: screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                    top: BorderSide(color: Colors.grey.shade300, width: 1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  ElevatedButton(
                    onPressed: _addToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBF0000),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(screenWidth * 0.08)),
                      padding:
                          EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                    ),
                    child: Center(
                      child: Text(
                        widget.isFromRewards
                            ? "Add to Cart ($_totalDisplay)"
                            : "Add to Cart ($_totalDisplay)",
                        style: TextStyle(
                            fontSize: screenWidth * 0.05, color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: screenHeight * 0.03,
                  )
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
        String? productPhoto = review["photo"] == "" ? null : review["photo"];
        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: productPhoto != null
                    ? NetworkImage(productPhoto)
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

  List<TextSpan> _buildProductNameSpans(String productName) {
    final words = productName.trim().split(RegExp(r'\s+'));
    if (words.length == 3) {
      return [
        TextSpan(text: '${words[0]} ${words[1]}\n'),
        TextSpan(text: words[2]),
      ];
    }
    return [TextSpan(text: productName)];
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
          activeColor: const Color(0xFFBF0000),
          checkColor: Colors.white,
        );
      }).toList(),
    );
  }

  Widget _buildPriceDisplay(Map<String, dynamic> item) {
    final DateTime now = DateTime.now();
    final Timestamp? start = item["Discount_Start_Date"];
    final Timestamp? end = item["Discount_End_Date"];

    bool isDiscountActive = false;
    if (start != null && end != null) {
      final DateTime startDate = start.toDate();
      final DateTime endDate = end.toDate();
      isDiscountActive = now.isAfter(startDate) && now.isBefore(endDate);
    }

    final double? price = (item["price"] as num?)?.toDouble();
    final double? discountPrice = (item["Discount_Price"] as num?)?.toDouble();

    if (price == null) return const Text("N/A");

    if (isDiscountActive && discountPrice != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${price.toStringAsFixed(3)} BHD",
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            "${discountPrice.toStringAsFixed(3)} BHD",
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFFBF0000),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    } else {
      return Text(
        "${price.toStringAsFixed(3)} BHD",
        style: const TextStyle(
          fontSize: 18,
          color: Color(0xFFBF0000),
          fontWeight: FontWeight.bold,
        ),
      );
    }
  }
}
