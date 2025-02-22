import 'package:flutter/material.dart';
import 'package:hometouch/Customer%20View/bottom_nav_bar.dart';
import 'package:hometouch/Customer%20View/review_page.dart';
import 'menu_page.dart';
import 'product_details_page.dart';
import 'cart_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesPage extends StatefulWidget {
  final bool isFromNavBar;

  const FavoritesPage({super.key, this.isFromNavBar = false});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  List<Map<String, dynamic>> favoriteVendors = [];
  List<Map<String, dynamic>> favoriteProducts = [];
  bool isLoading = true;
  int trackNavBarIcons = 1;
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();
    fetchFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final favoriteSnapshot = await FirebaseFirestore.instance
          .collection('Customer')
          .doc(user.uid)
          .collection('favorite')
          .get();

      List<Map<String, dynamic>> vendors = [];
      List<Map<String, dynamic>> products = [];

      for (var doc in favoriteSnapshot.docs) {
        var data = doc.data();
        String favoriteId = doc.id;

        if (data['Type'] == 'vendor') {
          final vendorDoc = await FirebaseFirestore.instance
              .collection('vendor')
              .doc(data['Vendor_ID'])
              .get();
          if (vendorDoc.exists && vendorDoc.data() != null) {
            var vendorData = vendorDoc.data() as Map<String, dynamic>;
            vendorData['id'] = vendorDoc.id;
            vendorData['Favorite_ID'] = favoriteId;
            vendors.add(vendorData);
          }
        } else if (data['Type'] == 'product') {
          if (data['Product_ID'] is DocumentReference) {
            DocumentReference productRef = data['Product_ID'];
            try {
              var productDoc = await productRef.get();
              if (productDoc.exists && productDoc.data() != null) {
                var productData = productDoc.data() as Map<String, dynamic>;
                productData['id'] = productDoc.id;
                productData['Image'] ??= 'https://via.placeholder.com/150';
                productData['Name'] ??= 'Unknown Product';
                productData['Favorite_ID'] = favoriteId;

                if (data.containsKey("Vendor_ID")) {
                  productData["Vendor_ID"] = data["Vendor_ID"];
                } else {
                  productData["Vendor_ID"] = "Unknown";
                }

                products.add(productData);
              }
            } catch (e) {
              print("❌ Error fetching product details: $e");
            }
          }
        }
      }

      if (!mounted) return;
      setState(() {
        favoriteVendors = vendors;
        favoriteProducts = products;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error fetching favorites: $e");
    }
  }

  Future<void> removeFavorite(String favoriteId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('Customer')
          .doc(user.uid)
          .collection('favorite')
          .doc(favoriteId)
          .delete();

      setState(() {
        favoriteVendors
            .removeWhere((item) => item['Favorite_ID'] == favoriteId);
        favoriteProducts
            .removeWhere((item) => item['Favorite_ID'] == favoriteId);
      });

      print("✅ Favorite successfully removed: $favoriteId");
    } catch (e) {
      print("❌ Error removing favorite: $e");
    }
  }

  void _reorderItem(Map<String, dynamic> item, bool isVendor) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final cartRef = FirebaseFirestore.instance
          .collection('Customer')
          .doc(user.uid)
          .collection('cart');

      var cartDocs = await cartRef.get();
      for (var doc in cartDocs.docs) {
        await doc.reference.delete();
      }

      if (isVendor) {
        QuerySnapshot productsSnapshot = await FirebaseFirestore.instance
            .collection('products')
            .where("Vendor_ID", isEqualTo: item['id'])
            .get();

        for (var doc in productsSnapshot.docs) {
          var product = doc.data() as Map<String, dynamic>;
          await cartRef.add({
            "name": product["Name"],
            "price": product["Price"] ?? 0.000,
            "quantity": 1,
            "addOns": product["AddOns"] ?? [],
            "image": product["Image"] ?? "",
            "vendorId": item["id"],
          });
        }
      } else {
        print("🛒 Vendor_ID before adding to cart: ${item["Vendor_ID"]}");

        await cartRef.add({
          "name": item["Name"],
          "price": item["Price"] ?? 0.000,
          "quantity": 1,
          "addOns": [],
          "image": item["Image"] ?? "",
          "vendorId": item["Vendor_ID"] ?? "Unknown",
        });
      }

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CartPage()),
      );
    } catch (e) {
      print("❌ Error reordering item: $e");
    }
  }

  void _rateItem(Map<String, dynamic> item, bool isVendor) async {
    if (isVendor) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewPage(vendorId: item['id']),
        ),
      );
    } else {
      String? categoryId;
      try {
        DocumentSnapshot productDoc = await FirebaseFirestore.instance
            .collection("vendor")
            .doc(item["Vendor_ID"])
            .collection("category")
            .doc(item["Category_ID"])
            .collection("products")
            .doc(item["id"])
            .get();

        if (productDoc.exists) {
          categoryId = item["Category_ID"];
        }
      } catch (e) {
        print("❌ Error fetching category ID: $e");
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewPage(
            productId: item['id'],
            categoryId: categoryId,
          ),
        ),
      );
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
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: widget.isFromNavBar
              ? const SizedBox()
              : Padding(
                  padding: EdgeInsets.only(
                    top: screenHeight * 0.03,
                    left: screenWidth * 0.02,
                    right: screenWidth * 0.02,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFBF0000),
                      ),
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(screenHeight * 0.01),
                      child: Padding(
                        padding: EdgeInsets.only(left: screenWidth * 0.02),
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: screenWidth * 0.055,
                        ),
                      ),
                    ),
                  ),
                ),
          title: Padding(
            padding: EdgeInsets.only(top: screenHeight * 0.02),
            child: Text(
              'Favorites',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: screenWidth * 0.06,
              ),
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFFBF0000),
            unselectedLabelColor: Colors.black54,
            indicatorColor: const Color(0xFFBF0000),
            indicatorWeight: 3,
            tabs: const [
              Tab(text: "Vendors", icon: Icon(Icons.store)),
              Tab(text: "Food", icon: Icon(Icons.fastfood)),
            ],
          ),
        ),
        body: Container(
          color: Colors.white,
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFBF0000)))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTab(favoriteVendors, true, screenWidth, screenHeight),
                    _buildTab(
                        favoriteProducts, false, screenWidth, screenHeight),
                  ],
                ),
        ),
        bottomNavigationBar: BottomNavBar(selectedIndex: 1),
        floatingActionButton: Container(
          height: 58,
          width: 58,
          child: FloatingActionButton(
            onPressed: () {
              if (_selectedIndex != 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CartPage(isFromNavBar: true)),
                );
              }
            },
            backgroundColor: const Color(0xFFBF0000),
            shape: const CircleBorder(),
            elevation: 5,
            child:
                const Icon(Icons.shopping_cart, color: Colors.white, size: 30),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget _buildTab(List<Map<String, dynamic>> items, bool isVendor,
      double screenWidth, double screenHeight) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          "No favorites found.",
          style: TextStyle(fontSize: screenWidth * 0.05, color: Colors.black54),
        ),
      );
    }

    return Scrollbar(
      controller: _scrollController,
      thickness: 4.0,
      radius: const Radius.circular(8.0),
      thumbVisibility: true,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(screenWidth * 0.04),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];

          if (item["id"] == null || item["Name"] == null) {
            return const SizedBox();
          }

          String imageUrl = (item["Image"] != null && item["Image"] != "")
              ? item["Image"]
              : 'https://via.placeholder.com/150';

          String name = item["Name"] ?? "Unknown Product";

          return GestureDetector(
            onTap: () {
              if (isVendor) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FoodMenuPage(vendorId: item['id']),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProductDetailsPage(productId: item["id"]),
                  ),
                );
              }
            },
            child: Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.grey[50]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: screenWidth * 0.08,
                            backgroundImage: NetworkImage(
                              isVendor
                                  ? (item["Logo"] ??
                                      "https://via.placeholder.com/50")
                                  : (imageUrl),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: screenWidth * 0.05,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const CircleAvatar(
                            backgroundColor: Color(0xFFBF0000),
                            radius: 16,
                            child: Icon(Icons.arrow_forward_ios,
                                color: Colors.white, size: 16),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: screenWidth / 3.5,
                            child: OutlinedButton(
                              onPressed: () => _rateItem(item, isVendor),
                              style: OutlinedButton.styleFrom(
                                side:
                                    const BorderSide(color: Color(0xFFBF0000)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                padding: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.015),
                              ),
                              child: const Text(
                                "Rate",
                                style: TextStyle(color: Color(0xFFBF0000)),
                              ),
                            ),
                          ),
                          if (!isVendor)
                            SizedBox(
                              width: screenWidth / 3.5,
                              child: ElevatedButton(
                                onPressed: () {
                                  _reorderItem(item, isVendor);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFBF0000),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      vertical: screenHeight * 0.019),
                                ),
                                child: const Text(
                                  "Reorder",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          IconButton(
                            onPressed: () =>
                                _showDeleteDialog(item['Favorite_ID']),
                            icon: const Icon(Icons.delete,
                                color: Color(0xFFBF0000)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteDialog(String favoriteId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Center(
            child: Text(
              "Delete Favorite",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          content: const Text(
            "Are you sure you want to delete this favorite?",
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
                  onPressed: () async {
                    await removeFavorite(favoriteId);
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child:
                      const Text("YES", style: TextStyle(color: Colors.white)),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFBF0000)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("NO",
                      style: TextStyle(color: Color(0xFFBF0000))),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
