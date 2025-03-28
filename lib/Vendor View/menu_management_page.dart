import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hometouch/Customer%20View/review_page.dart';
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

  Widget _buildImage(
    String? image,
    String productName,
    double screenWidth,
    double screenHeight,
  ) {
    double imageWidth = screenWidth * 0.479;
    double imageHeight = screenHeight * 0.135;

    if (image == null || image.isEmpty) {
      return SizedBox(
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
      return SizedBox(
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
      return SizedBox(
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
        String name = doc['Name'] ?? '';
        String image = doc['Image'] ?? 'https://via.placeholder.com/150';
        double price = (doc['Price'] as num?)?.toDouble() ?? 0.0;

        if (name.isNotEmpty && price > 0) {
          products.add({
            'id': doc.id,
            'name': name,
            'price': price,
            'image': image,
            'categoryId': categoryId,
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

  void showDeleteConfirmationDialog(
    BuildContext context,
    String categoryId,
    String productId,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
          title: const Text(
            'Delete Product?',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFBF0000),
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                alignment: Alignment.center,
                child: const Text(
                  'Are you sure you want to delete this product?',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFBF0000)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: () async {
                        await _deleteProduct(categoryId, productId);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Yes',
                        style: TextStyle(
                          color: Color(0xFFBF0000),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFBF0000),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'No',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
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
              crossAxisSpacing: screenWidth * 0.001,
              mainAxisSpacing: screenHeight * 0.02,
              childAspectRatio: 0.8,
            ),
            itemCount: items.length,
            itemBuilder: (context, itemIndex) {
              final item = items[itemIndex];
              return Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
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
                        top: screenWidth * 0.02,
                        left: screenWidth * 0.02,
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
                        vertical: item['name'].length > 20
                            ? screenHeight * 0.01
                            : screenHeight * 0.0235,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${item['price'].toStringAsFixed(3)} BHD',
                            style: TextStyle(
                              color: const Color(0xFFBF0000),
                              fontWeight: FontWeight.bold,
                              fontSize: screenWidth * 0.04,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  size: screenWidth * 0.05,
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
                                  ).then((_) {
                                    _fetchCategories();
                                  });
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  size: screenWidth * 0.05,
                                  color: const Color(0xFFBF0000),
                                ),
                                onPressed: () {
                                  showDeleteConfirmationDialog(
                                    context,
                                    item["categoryId"],
                                    item["id"],
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          )
        else
          Center(
            child: Text(
              'No products available',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
              ),
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
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFBF0000),
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
              thickness: screenHeight * 0.001,
              color: Colors.grey[300],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductPage()),
          ).then((_) {
            _fetchCategories();
          });
        },
        backgroundColor: const Color(0xFFBF0000),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFBF0000),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.02,
                    ),
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
                              ? Icon(
                                  Icons.fastfood,
                                  size: screenWidth * 0.12,
                                  color: Colors.white,
                                )
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
                            ],
                          ),
                        ),
                        IconButton(
                          icon: CircleAvatar(
                            backgroundColor: const Color(0xFFBF0000),
                            child: Icon(
                              Icons.rate_review,
                              color: Colors.white,
                              size: screenWidth * 0.06,
                            ),
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
                        return GestureDetector(
                          onTap: () => scrollToCategory(category),
                          child: Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.02,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04,
                              vertical: screenHeight * 0.01,
                            ),
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
}
