import 'package:flutter/material.dart';
import 'package:hometouch/Customer%20View/acoount_page.dart';
import 'package:hometouch/Customer%20View/cart_page2.dart';
import 'package:hometouch/Customer%20View/home_page.dart';
import 'menu_page.dart'; // For the vendor menu page
import 'add_product_review.dart' as review; // Using 'review' as a prefix
import 'product_details_page.dart'; // For the ProductDetailsPage
import 'cart_page.dart'; // For the CartPage
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> favoriteVendors = [];
  List<Map<String, dynamic>> favoriteProducts = [];
  bool isLoading = true;
  int trackNavBarIcons = 1;
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  HomeTouchScreen()), // Navigate to SettingsPage
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  FavoritesPage()), // Navigate to SettingsPage
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  FavoritesPage()), // Navigate to SettingsPage
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AccountPage()), // Navigate to SettingsPage
        );
        break;
    }
    setState(() {
      _selectedIndex = index; // Update the selected index
    });
    // You can add additional logic here to navigate or update UI as needed
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
        String Favorite_ID = doc.id; // ✅ Store favorite doc ID

        if (data['Type'] == 'vendor') {
          final vendorDoc = await FirebaseFirestore.instance
              .collection('vendor')
              .doc(data['Vendor_ID'])
              .get();

          if (vendorDoc.exists && vendorDoc.data() != null) {
            var vendorData = vendorDoc.data() as Map<String, dynamic>;
            vendorData['id'] = vendorDoc.id;
            vendorData['Favorite_ID'] = Favorite_ID; // ✅ Store favorite ID
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
                productData['Favorite_ID'] = Favorite_ID; // ✅ Store favorite ID

                products.add(productData);
              }
            } catch (e) {
              print("❌ Error fetching product details: $e");
            }
          }
        }
      }

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
      // ✅ Wait for Firestore deletion before updating the UI
      await FirebaseFirestore.instance
          .collection('Customer')
          .doc(user.uid)
          .collection('favorite')
          .doc(favoriteId)
          .delete();

      // ✅ Ensure UI updates correctly for both vendors and products
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

  void _reorderItem(Map<String, dynamic> item) {
    // Create a cart item with default values
    Map<String, dynamic> cartItem = {
      "name": item["name"],
      "price": 3.000, // Default base price
      "quantity": 1, // Default quantity
      "addOns": [], // No add-ons by default
    };

    // Navigate to the CartPage with the reordered item
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartPage(cartItems: [cartItem]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to adapt to screen size
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: Padding(
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
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildTab(favoriteVendors, true, screenWidth, screenHeight),
                  _buildTab(favoriteProducts, false, screenWidth, screenHeight),
                ],
              ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 2,
        color: Colors.white,
        child: SizedBox(
          height: 50, // ✅ Adjust height
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, "Home", 0),
              _buildNavItem(Icons.favorite_border, "Favorite", 1),
              const SizedBox(width: 40), // Space for FloatingActionButton
              _buildNavItem(Icons.list_alt, "Orders", 3),
              _buildNavItem(Icons.account_circle, "Account", 4),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CartPage2()),
              );
            },
            backgroundColor: const Color(0xFFBF0000),
            shape: const CircleBorder(),
            elevation: 5,
            child:
                const Icon(Icons.shopping_cart, color: Colors.white, size: 30),
          ),

          // ✅ Show "Cart" label ONLY when cart is selected
          if (_selectedIndex == 2) ...[
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: 1.0, // 🔽 Only show label when selected
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
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isSelected ? 32 : 22, // 🔼 Enlarges when selected
            color: isSelected ? const Color(0xFFBF0000) : Colors.black45,
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isSelected ? 1.0 : 0.0, // 🔽 Only show label when selected
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFFBF0000)),
            ),
          ),
        ],
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
      thickness: 4.0,
      radius: const Radius.circular(8.0),
      thumbVisibility: true,
      child: ListView.builder(
        padding: EdgeInsets.all(
            screenWidth * 0.04), // Dynamic padding based on screen width
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          String imageUrl = item["Image"] ?? 'https://via.placeholder.com/150';
          String name = item["Name"] ?? "Unknown";
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
                          ProductDetailsPage(productId: item["id"])),
                );
              }
            },
            child: Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.02), // Dynamic vertical margin
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
                  padding: EdgeInsets.all(screenWidth *
                      0.04), // Dynamic padding based on screen width
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: screenWidth *
                                0.08, // Dynamic size based on screen width
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
                              (name),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize:
                                    screenWidth * 0.05, // Dynamic font size
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
                      SizedBox(height: screenHeight * 0.02), // Dynamic spacing
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: screenWidth /
                                3.5, // Dynamic width based on screen size
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        review.AddProductReviewPage(
                                      // Use prefixed import
                                      productName: item["name"] ?? "Unknown",
                                    ),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side:
                                    const BorderSide(color: Color(0xFFBF0000)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                padding: EdgeInsets.symmetric(
                                    vertical: screenHeight *
                                        0.015), // Dynamic padding
                              ),
                              child: const Text(
                                "Rate",
                                style: TextStyle(color: Color(0xFFBF0000)),
                              ),
                            ),
                          ),
                          if (!isVendor)
                            SizedBox(
                              width: screenWidth /
                                  3.5, // Dynamic width based on screen size
                              child: ElevatedButton(
                                onPressed: () {
                                  _reorderItem(
                                      item); // Call the reorder function
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFBF0000),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      vertical: screenHeight *
                                          0.019), // Dynamic padding
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
                    await removeFavorite(
                        favoriteId); // ✅ Wait for Firestore to delete
                    if (mounted) {
                      Navigator.of(context).pop(); // ✅ Close after deletion
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
