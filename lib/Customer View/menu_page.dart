import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hometouch/Customer%20View/cart_page.dart';
import 'package:hometouch/Customer%20View/product_details_page.dart';

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
  String selectedCategory = ""; // Default to show all products
  Map<String, List<Map<String, dynamic>>> menuItems = {};
  List<String> categories = []; // Remove "All" as the first category
  Map<String, dynamic> vendorDetails = {};
  bool isLoading = true;
  bool isFavorite = false; // Track favorite status
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

  // Check if the vendor is already favorited
  Future<void> _checkIfFavorite() async {
    if (customerId == null) return; // Skip if no user is signed in

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

  // Remove any navigation from the favorite toggle function
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

  // Build the image widget with a fallback
  Widget _buildImage(String? image, String productName) {
    if (image == null || image.isEmpty) {
      return Container(
        width: 150,
        height: 100,
        child: Image.asset(
          'assets/placeholder_image.jpg',
          fit: BoxFit.cover,
        ),
      );
    }

    try {
      Uri.parse(image); // Attempt to parse the URL

      return Container(
        width: 150,
        height: 100,
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
        width: 150,
        height: 100,
        child: Image.asset(
          'assets/placeholder_image.jpg',
          fit: BoxFit.cover,
        ),
      );
    }
  }

  // Fetch vendor details like name and rating
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

  // Fetch categories and products from Firebase
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

  // Fetch products for each category
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
            'id': doc.id, // ✅ Include Product ID (doc.id)
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: CircleAvatar(
            backgroundColor: const Color(0xFFBF0000),
            child: Padding(
              padding: EdgeInsets.only(left: screenWidth * 0.02),
              child: Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: screenWidth * 0.055,
              ),
            ),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: CircleAvatar(
              backgroundColor: const Color(0xFFBF0000),
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: Colors.white,
              ),
            ),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: Stack(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFBF0000),
                  child:
                      Icon(Icons.shopping_cart_outlined, color: Colors.white),
                ),
                if (cartItemCount > 0)
                  Positioned(
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$cartItemCount',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFBF0000),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CartPage(),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to ChatPage when pressed
        },
        backgroundColor: const Color(0xFFBF0000),
        child: const Icon(Icons.message, color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Divider between AppBar and Vendor Details
                const Divider(thickness: 1, height: 1, color: Colors.black12),
                // Vendor Info Section
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
                              crossAxisAlignment: CrossAxisAlignment
                                  .start, // Align text to the start
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: const Color(0xFFBF0000),
                                      size: screenWidth * 0.05,
                                    ),
                                    SizedBox(
                                        width: screenWidth *
                                            0.01), // Add spacing between icon and text
                                    Text(
                                      '${vendorDetails['Rating'] ?? '0.0'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                    height: screenHeight *
                                        0.005), // Add spacing between the two lines
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
                              color: Colors.white, size: screenWidth * 0.05),
                        ),
                        onPressed: () {
                          // Navigate to the AllReviewsPage
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(thickness: 1, height: 20, color: Colors.black12),
                // Categories Navigation
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
                // Menu Items
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
                                          // Navigate to ProductDetailsPage when tapping the entire box
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ProductDetailsPage(
                                                      productId: item["id"]),
                                            ),
                                          );
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
                                                    item['name']),
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
                                                        // Navigate when tapping the "+" button
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
