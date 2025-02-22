import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hometouch/Customer%20View/cart_page.dart';
import 'package:hometouch/Customer%20View/product_details_page.dart';
import 'package:hometouch/Customer%20View/review_page.dart';

class FoodMenuPage extends StatefulWidget {
  final String vendorId;

  const FoodMenuPage({required this.vendorId, Key? key}) : super(key: key);

  @override
  State<FoodMenuPage> createState() => _FoodMenuPageState();
}

class _FoodMenuPageState extends State<FoodMenuPage> {
  late ScrollController _scrollController;
  final ScrollController _categoriesScrollController = ScrollController();
  final Map<String, GlobalKey> _categoryKeys = {};
  String selectedCategory = "";
  Map<String, List<Map<String, dynamic>>> menuItems = {};
  List<String> categories = [];
  Map<String, dynamic> vendorDetails = {};
  bool isLoading = true;
  bool isFavorite = false;
  String? customerId;
  int cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _fetchVendorDetails();
    _fetchCategories();
    _getCurrentUserId();
    _checkIfFavorite();
    _fetchCartItemCount();
    _initializeUserAndCart();
  }

  Future<void> _initializeUserAndCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        customerId = user.uid;
      });
      await _resetCartIfVendorMismatch();
      await _fetchCartItemCount();
    } else {
      print("No user is currently signed in.");
    }
  }

  Future<void> _resetCartIfVendorMismatch() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cartSnapshot = await FirebaseFirestore.instance
        .collection('Customer')
        .doc(user.uid)
        .collection('cart')
        .get();

    bool vendorMismatch = false;
    for (var doc in cartSnapshot.docs) {
      final data = doc.data();
      if (data['vendorId'] != widget.vendorId) {
        vendorMismatch = true;
        break;
      }
    }

    if (vendorMismatch) {
      for (var doc in cartSnapshot.docs) {
        await doc.reference.delete();
      }
      setState(() {
        cartItemCount = 0;
        _fetchCartItemCount();
      });
      print("Cart has been reset due to vendor mismatch.");
    }
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

  Future<void> _checkIfFavorite() async {
    if (customerId == null) return;
    try {
      final favoriteSnapshot = await FirebaseFirestore.instance
          .collection('Customer')
          .doc(customerId)
          .collection('favorite')
          .where('Vendor_ID', isEqualTo: widget.vendorId)
          .where('Type', isEqualTo: 'vendor')
          .get();

      if (favoriteSnapshot.docs.isNotEmpty) {
        setState(() {
          isFavorite = true;
        });
      }
    } catch (e) {
      print("Error checking favorite: $e");
    }
  }

  Future<void> _toggleFavorite() async {
    if (customerId == null) return;

    try {
      final favoriteRef = FirebaseFirestore.instance
          .collection('Customer')
          .doc(customerId)
          .collection('favorite')
          .doc(widget.vendorId);

      if (isFavorite) {
        await favoriteRef.delete();
      } else {
        await favoriteRef.set({'Vendor_ID': widget.vendorId, 'Type': 'vendor'});
      }

      setState(() {
        isFavorite = !isFavorite;
      });
    } catch (e) {
      print("Error toggling favorite: $e");
    }
  }

  Widget _buildImage(String? image, String productName, double screenWidth,
      double screenHeight) {
    double imageWidth = screenWidth * 0.47;
    double imageHeight = screenHeight * 0.135;

    if (image == null || image.isEmpty) {
      return Container(
        width: imageWidth,
        height: imageHeight,
        child: Image.asset(
          'assets/placeholder_image.jpg',
          fit: BoxFit.cover,
        ),
      );
    }

    try {
      Uri.parse(image);

      return Container(
        width: imageWidth,
        height: imageHeight,
        child: Image.network(
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
    } catch (e) {
      return Container(
        width: imageWidth,
        height: imageHeight,
        child: Image.asset(
          'assets/placeholder_image.jpg',
          fit: BoxFit.cover,
        ),
      );
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

      if (mounted) {
        setState(() {
          categories = tempCategories;
          menuItems = newMenuItems;
          if (categories.isNotEmpty) {
            selectedCategory = categories[0];
          }
          isLoading = false;
        });
      }
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
        String name = doc['Name'] ?? '';
        String image = doc['Image'] ?? 'https://via.placeholder.com/150';
        double price = (doc['Price'] as num?)?.toDouble() ?? 0.0;

        if (name.isNotEmpty && price > 0) {
          products.add({
            'id': doc.id,
            'name': name,
            'price': price,
            'image': image,
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

  Future<void> _fetchCartItemCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final cartSnapshot = await FirebaseFirestore.instance
          .collection('Customer')
          .doc(user.uid)
          .collection('cart')
          .get();

      setState(() {
        cartItemCount = cartSnapshot.docs.length;
      });
    } catch (e) {
      print("❌ Error fetching cart count: $e");
    }
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
          backgroundColor: Colors.white,
          elevation: 0,
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
            Padding(
              padding: EdgeInsets.only(
                  top: screenHeight * 0.02, right: screenWidth * 0.02),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartPage(),
                    ),
                  ).then((_) {
                    _fetchCartItemCount();
                  });
                },
                child: Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFFBF0000),
                      radius: screenHeight * 0.027,
                      child: Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.white,
                        size: screenHeight * 0.027,
                      ),
                    ),
                    if (cartItemCount > 0)
                      Positioned(
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color.fromARGB(255, 238, 238, 238),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$cartItemCount',
                            style: TextStyle(
                              fontSize: screenHeight * 0.018,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFBF0000),
                            ),
                          ),
                        ),
                      ),
                  ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFBF0000),
        child: const Icon(Icons.message, color: Colors.white),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
              color: Color(0xFFBF0000),
            ))
          : Column(
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
                        radius: screenWidth * 0.1,
                        backgroundColor: Colors.grey,
                        backgroundImage: vendorDetails['Logo'] != null
                            ? NetworkImage(vendorDetails['Logo'])
                            : null,
                        child: vendorDetails['Logo'] == null
                            ? Icon(Icons.fastfood,
                                size: screenWidth * 0.12, color: Colors.white)
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
                                fontSize: screenWidth * 0.06,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: const Color(0xFFBF0000),
                                      size: screenWidth * 0.05,
                                    ),
                                    SizedBox(width: screenWidth * 0.01),
                                    Text(
                                      '${vendorDetails['Rating'] ?? '0.0'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: screenHeight * 0.005),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.delivery_dining,
                                      color: const Color(0xFFBF0000),
                                      size: 16,
                                    ),
                                    SizedBox(width: screenWidth * 0.01),
                                    Text(
                                      "BHD 0.600",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: CircleAvatar(
                          backgroundColor: const Color(0xFFBF0000),
                          child: Icon(Icons.rate_review,
                              color: Colors.white, size: screenWidth * 0.06),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ReviewPage(vendorId: widget.vendorId),
                            ),
                          ).then((_) {
                            _fetchVendorDetails();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Divider(
                  thickness: screenHeight * 0.001,
                  color: Colors.grey[300],
                ),
                SizedBox(
                  height: screenHeight * 0.06,
                  child: ListView.builder(
                    controller: _categoriesScrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      _categoryKeys[category] = GlobalKey();
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
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              category,
                              style: TextStyle(
                                color: selectedCategory == category
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: screenWidth * 0.04,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final items = menuItems[category] ?? [];

                        return Column(
                          key: _categoryKeys[category],
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.04),
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.05,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            items.isNotEmpty
                                ? GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: screenWidth * 0.02,
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
                                              builder: (context) =>
                                                  ProductDetailsPage(
                                                      productId: item["id"]),
                                            ),
                                          ).then((_) {
                                            _fetchCartItemCount();
                                          });
                                        },
                                        child: Card(
                                          color: Colors.white,
                                          elevation: 4,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                  top: Radius.circular(15),
                                                ),
                                                child: _buildImage(
                                                    item['image'],
                                                    item['name'],
                                                    screenWidth,
                                                    screenHeight),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.all(
                                                    screenWidth * 0.02),
                                                child: Text(
                                                  item['name'],
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize:
                                                        screenWidth * 0.04,
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      screenWidth * 0.02,
                                                  vertical:
                                                      item['name'].length > 18
                                                          ? screenHeight * 0.01
                                                          : screenHeight *
                                                              0.0235,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      '${item['price'].toStringAsFixed(3)} BHD',
                                                      style: TextStyle(
                                                        color: const Color(
                                                            0xFFBF0000),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize:
                                                            screenWidth * 0.04,
                                                      ),
                                                    ),
                                                    GestureDetector(
                                                      onTap: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                ProductDetailsPage(
                                                                    productId:
                                                                        item[
                                                                            "id"]),
                                                          ),
                                                        );
                                                      },
                                                      child: Container(
                                                        padding: EdgeInsets.all(
                                                            screenWidth * 0.02),
                                                        decoration:
                                                            const BoxDecoration(
                                                          color:
                                                              Color(0xFFBF0000),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        child: Icon(
                                                          Icons.add,
                                                          color: Colors.white,
                                                          size: screenWidth *
                                                              0.04,
                                                        ),
                                                      ),
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
                                : Center(
                                    child: Text(
                                      'No products available',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.04,
                                      ),
                                    ),
                                  ),
                            SizedBox(height: screenHeight * 0.08),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
