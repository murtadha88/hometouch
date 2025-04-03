import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hometouch/Common%20Pages/product_details_page.dart';
import 'package:hometouch/Common%20Pages/review_page.dart';
import 'package:hometouch/Vendor%20View/add_product_page.dart';
import 'package:hometouch/Vendor%20View/edit_product_page.dart';

class FoodMenuPage extends StatefulWidget {
  final String vendorId;

  const FoodMenuPage({required this.vendorId, Key? key}) : super(key: key);

  @override
  State<FoodMenuPage> createState() => _FoodMenuPageState();
}

class _FoodMenuPageState extends State<FoodMenuPage> {
  final ScrollController _categoriesScrollController = ScrollController();
  final Map<String, GlobalKey> _categoryKeys = {};

  String selectedCategory = "";
  Map<String, List<Map<String, dynamic>>> menuItems = {};
  List<String> categories = [];
  Map<String, dynamic> vendorDetails = {};
  bool isLoading = true;
  String? customerId;

  @override
  void initState() {
    super.initState();
    _fetchVendorDetails();
    _fetchCategories();
    _getCurrentUserId();
  }

  void _getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        customerId = user.uid;
      });
    } else {
      print("No user is currently signed in.");
    }
  }

  Future<void> _fetchVendorDetails() async {
    try {
      DocumentSnapshot vendorSnapshot = await FirebaseFirestore.instance
          .collection('vendor')
          .doc(widget.vendorId)
          .get();

      if (vendorSnapshot.exists) {
        setState(() {
          vendorDetails = vendorSnapshot.data() as Map<String, dynamic>;
        });
      }
    } catch (e) {
      print("Error fetching vendor details: $e");
    }
  }

  Future<void> _fetchCategories() async {
    try {
      QuerySnapshot categorySnapshot = await FirebaseFirestore.instance
          .collection('vendor')
          .doc(widget.vendorId)
          .collection('category')
          .get();

      List<String> tempCategories = [];
      Map<String, List<Map<String, dynamic>>> newMenuItems = {};

      for (var doc in categorySnapshot.docs) {
        String categoryName = doc['Name'] ?? '';
        tempCategories.add(categoryName);
        newMenuItems[categoryName] = await _fetchProducts(doc.id);
      }

      setState(() {
        categories = tempCategories;
        menuItems = newMenuItems;
        if (categories.isNotEmpty) {
          selectedCategory = categories[0];
        }
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }

  Future<List<Map<String, dynamic>>> _fetchProducts(String categoryId) async {
    try {
      QuerySnapshot productSnapshot = await FirebaseFirestore.instance
          .collection('vendor')
          .doc(widget.vendorId)
          .collection('category')
          .doc(categoryId)
          .collection('products')
          .get();

      List<Map<String, dynamic>> products = [];
      for (var doc in productSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};

        String name = data['Name'] ?? '';
        String image = data['Image'] ?? 'https://via.placeholder.com/150';
        double price = (data['Price'] as num?)?.toDouble() ?? 0.0;

        if (name.isNotEmpty && price > 0) {
          products.add({
            'id': doc.id,
            'name': name,
            'price': price,
            'image': image,
            'categoryId': categoryId,
            'Discount_Price': data.containsKey('Discount_Price')
                ? data['Discount_Price']
                : null,
            'Discount_Start_Date': data.containsKey('Discount_Start_Date')
                ? data['Discount_Start_Date']
                : null,
            'Discount_End_Date': data.containsKey('Discount_End_Date')
                ? data['Discount_End_Date']
                : null,
          });
        }
      }

      return products;
    } catch (e) {
      print("Error fetching products for $categoryId: $e");
      return [];
    }
  }

  void scrollToCategory(String category) {
    final key = _categoryKeys[category];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        selectedCategory = category;
      });
    }
  }

  Future<void> _deleteProduct(String categoryId, String productId) async {
    try {
      await FirebaseFirestore.instance
          .collection('vendor')
          .doc(widget.vendorId)
          .collection('category')
          .doc(categoryId)
          .collection('products')
          .doc(productId)
          .delete();
      _fetchCategories();
    } catch (e) {
      print("Error deleting product: $e");
    }
  }

  Widget _buildImage(
    String? image,
    String productName,
    double screenWidth,
    double screenHeight,
  ) {
    double imageWidth = screenWidth * 0.479;
    double imageHeight = screenHeight * 0.135;

    return SizedBox(
      width: imageWidth,
      height: imageHeight,
      child: (image == null || image.isEmpty)
          ? Image.asset('assets/placeholder_image.jpg', fit: BoxFit.cover)
          : Image.network(
              image,
              fit: BoxFit.cover,
              errorBuilder: (context, object, stackTrace) {
                return Image.asset(
                  'assets/placeholder_image.jpg',
                  fit: BoxFit.cover,
                );
              },
            ),
    );
  }

  Widget _buildCategorySection(BuildContext context, String category,
      double screenWidth, double screenHeight) {
    final items = menuItems[category] ?? [];
    _categoryKeys[category] = GlobalKey();

    return Column(
      key: _categoryKeys[category],
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: Text(
            category,
            style: TextStyle(
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: screenHeight * 0.01),
        if (items.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: screenWidth * 0.03,
              mainAxisSpacing: screenHeight * 0.02,
              childAspectRatio: 0.8,
            ),
            itemCount: items.length,
            itemBuilder: (context, itemIndex) {
              final item = items[itemIndex];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailsPage(
                        productId: item['id'],
                        isFromRewards: false,
                        isVendorView: true,
                      ),
                    ),
                  );
                },
                child: Card(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.04),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(screenWidth * 0.04),
                        ),
                        child: _buildImage(
                          item['image'],
                          item['name'],
                          screenWidth,
                          screenHeight,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          top: screenHeight * 0.01,
                          left: screenWidth * 0.03,
                        ),
                        child: Text(
                          item['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.04,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.02,
                          vertical: screenHeight * 0.01,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildPriceDisplay(item, screenWidth),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(
                                    Icons.edit,
                                    size: screenWidth * 0.055,
                                    color: const Color(0xFFBF0000),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditProductPage(
                                          vendorId: widget.vendorId,
                                          categoryId: item["categoryId"],
                                          productId: item["id"],
                                        ),
                                      ),
                                    ).then((_) => _fetchCategories());
                                  },
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(
                                    Icons.delete,
                                    size: screenWidth * 0.055,
                                    color: const Color(0xFFBF0000),
                                  ),
                                  onPressed: () => showDeleteConfirmationDialog(
                                    context,
                                    item["categoryId"],
                                    item["id"],
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
              );
            },
          )
        else
          Center(
            child: Text(
              'No products available',
              style: TextStyle(fontSize: screenWidth * 0.04),
            ),
          ),
        SizedBox(height: screenHeight * 0.03),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
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
              'Menu Management',
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddProductPage()),
        ).then((_) => _fetchCategories()),
        backgroundColor: const Color(0xFFBF0000),
        child: Icon(Icons.add, color: Colors.white, size: screenWidth * 0.08),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: const Color(0xFFBF0000),
                  strokeWidth: screenWidth * 0.02),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.02),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: screenWidth * 0.12,
                          backgroundColor: Colors.grey,
                          backgroundImage: vendorDetails['Logo'] != null
                              ? NetworkImage(vendorDetails['Logo'])
                              : null,
                          child: vendorDetails['Logo'] == null
                              ? Icon(Icons.fastfood,
                                  size: screenWidth * 0.15, color: Colors.white)
                              : null,
                        ),
                        SizedBox(width: screenWidth * 0.04),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vendorDetails['Name'] ?? 'Vendor Name',
                                style: TextStyle(
                                    fontSize: screenWidth * 0.05,
                                    fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Row(
                                children: [
                                  Icon(Icons.star,
                                      color: const Color(0xFFBF0000),
                                      size: screenWidth * 0.05),
                                  SizedBox(width: screenWidth * 0.01),
                                  Text(
                                    '${vendorDetails['Rating'] ?? '0.0'}',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: screenWidth * 0.04),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: CircleAvatar(
                            backgroundColor: const Color(0xFFBF0000),
                            radius: screenWidth * 0.07,
                            child: Icon(Icons.rate_review,
                                color: Colors.white, size: screenWidth * 0.06),
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReviewPage(
                                vendorId: widget.vendorId,
                                isVendor: true,
                              ),
                            ),
                          ).then((_) => _fetchVendorDetails()),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                      thickness: screenHeight * 0.001, color: Colors.grey[300]),
                  SizedBox(
                    height: screenHeight * 0.06,
                    child: ListView.builder(
                      controller: _categoriesScrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return GestureDetector(
                          onTap: () => scrollToCategory(category),
                          child: Container(
                            margin: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.02),
                            padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.04,
                                vertical: screenHeight * 0.01),
                            decoration: BoxDecoration(
                              color: selectedCategory == category
                                  ? const Color(0xFFBF0000)
                                  : Colors.grey[200],
                              borderRadius:
                                  BorderRadius.circular(screenWidth * 0.1),
                            ),
                            child: Center(
                              child: Text(
                                category,
                                style: TextStyle(
                                    color: selectedCategory == category
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: screenWidth * 0.04),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  for (String category in categories)
                    _buildCategorySection(
                      context,
                      category,
                      screenWidth,
                      screenHeight,
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildPriceDisplay(Map<String, dynamic> item, double screenWidth) {
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

    TextStyle defaultStyle = TextStyle(
      fontSize: screenWidth * 0.035,
      color: const Color(0xFFBF0000),
      fontWeight: FontWeight.bold,
    );

    if (isDiscountActive && discountPrice != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${price.toStringAsFixed(3)} BHD",
            style: defaultStyle.copyWith(
              color: Colors.black54,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          Text(
            "${discountPrice.toStringAsFixed(3)} BHD",
            style: defaultStyle,
          ),
        ],
      );
    } else {
      return Text(
        "${price.toStringAsFixed(3)} BHD",
        style: defaultStyle,
      );
    }
  }

  void showDeleteConfirmationDialog(
    BuildContext context,
    String categoryId,
    String productId,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.03, horizontal: screenWidth * 0.04),
          title: Text(
            'Delete Product?',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: screenWidth * 0.06,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFBF0000)),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: screenHeight * 0.01),
              Text(
                'Are you sure you want to delete this product?',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFBF0000)),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(screenWidth * 0.02)),
                          padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.02)),
                      onPressed: () async {
                        await _deleteProduct(categoryId, productId);
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Yes',
                        style: TextStyle(
                            color: const Color(0xFFBF0000),
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.04),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBF0000),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(screenWidth * 0.02)),
                          padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.02)),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'No',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.04),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
