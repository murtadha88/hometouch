import 'package:flutter/material.dart';
import 'dart:async';
// import 'drawer_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeTouchScreen extends StatefulWidget {
  const HomeTouchScreen({super.key});

  @override
  State<HomeTouchScreen> createState() => _HomeTouchScreenState();
}

//----------------------- Variables-----------------------
class _HomeTouchScreenState extends State<HomeTouchScreen> {
  // final List<bool> _isFavorite = [false, false, false];
  bool isHomeVendorSelected = false;
  bool isFoodTruckSelected = false;
  PageController _pageController = PageController();
  int _currentIndex = 0;
  int currentMenuIndex = 0;
  int trackNavBarIcons = 0;

  final GlobalKey allVendorsKey = GlobalKey();

  final List<String> images = [
    'https://i.imgur.com/rAr9H3z.jpeg',
    'https://i.imgur.com/PdD9UDt.jpeg',
    'https://i.imgur.com/1XXOKNE.jpeg'
  ];

  final List<String> categories = [
    "Trending",
    "5 ★",
    "4 ★",
    "3 ★",
    "2 ★",
    "1 ★",
  ];

  String? selectedCategory;
  final ScrollController _categoriesScrollController = ScrollController();
  final ScrollController _allVendorsScrollController = ScrollController();

  List<Map<String, dynamic>> allVendors = [];
  List<Map<String, dynamic>> filteredVendors = [];
  bool isFetching = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchAllVendors();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (_currentIndex < images.length - 1) {
          _currentIndex++;
        } else {
          _currentIndex = 0;
        }

        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _currentIndex,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _categoriesScrollController.dispose();
    _allVendorsScrollController.dispose();
    super.dispose();
  }

  Stream<List<Map<String, dynamic>>> fetchVendors() {
    return FirebaseFirestore.instance
        .collection('vendor')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<List<Map<String, dynamic>>> fetchRecommendedVendors(
      String userId) async {
    try {
      final customerRef =
          FirebaseFirestore.instance.collection('Customer').doc(userId);

      final ordersQuery = await FirebaseFirestore.instance
          .collection('order')
          .where('Customer_ID', isEqualTo: customerRef)
          .get();

      if (ordersQuery.docs.isNotEmpty) {
        final Map<String, int> vendorOrderCount = {};

        for (var doc in ordersQuery.docs) {
          final vendorRef = doc['Vendor_ID'] as DocumentReference?;
          if (vendorRef != null) {
            final vendorId = vendorRef.id;
            vendorOrderCount[vendorId] = (vendorOrderCount[vendorId] ?? 0) + 1;
          }
        }

        final sortedVendors = vendorOrderCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final sortedVendorIds =
            sortedVendors.map((entry) => entry.key).toList();

        final vendorsQuery = await FirebaseFirestore.instance
            .collection('vendor')
            .where(FieldPath.documentId, whereIn: sortedVendorIds)
            .get();

        final vendors = vendorsQuery.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          data['Order_Count'] = vendorOrderCount[doc.id];
          return data;
        }).toList();

        vendors.sort((a, b) =>
            (b['Order_Count'] as int).compareTo(a['Order_Count'] as int));

        return vendors;
      }

      final topVendorsQuery = await FirebaseFirestore.instance
          .collection('vendor')
          .orderBy('Rating', descending: true)
          .limit(3)
          .get();

      return topVendorsQuery.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching recommended vendors: $e');
      return [];
    }
  }

  Future<void> fetchAllVendors() async {
    try {
      final vendorsSnapshot =
          await FirebaseFirestore.instance.collection('vendor').get();

      setState(() {
        allVendors = vendorsSnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        filteredVendors = allVendors;
      });
    } catch (e) {
      print("Error fetching vendors: $e");
    }
  }

  Future<void> fetchVendorsByFilter(String category) async {
    setState(() {
      isFetching = true;
    });

    try {
      if (category == "Trending") {
        final ordersSnapshot =
            await FirebaseFirestore.instance.collection('order').get();

        final Map<String, int> vendorOrderCount = {};
        for (var orderDoc in ordersSnapshot.docs) {
          final vendorRef = orderDoc['Vendor_ID'] as DocumentReference?;
          if (vendorRef != null) {
            final vendorId = vendorRef.id;
            vendorOrderCount[vendorId] = (vendorOrderCount[vendorId] ?? 0) + 1;
          }
        }

        final sortedVendors = vendorOrderCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topVendorIds =
            sortedVendors.take(10).map((entry) => entry.key).toList();

        final topVendorsSnapshot = await FirebaseFirestore.instance
            .collection('vendor')
            .where(FieldPath.documentId, whereIn: topVendorIds)
            .get();

        setState(() {
          filteredVendors = topVendorsSnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            data['Order_Count'] = vendorOrderCount[doc.id];
            return data;
          }).toList();
        });
      } else {
        double minRating;
        double maxRating;

        if (category == "5 ★") {
          minRating = 5.0;
          maxRating = 5.0;
        } else if (category == "4 ★") {
          minRating = 4.0;
          maxRating = 4.9;
        } else if (category == "3 ★") {
          minRating = 3.0;
          maxRating = 3.9;
        } else if (category == "2 ★") {
          minRating = 2.0;
          maxRating = 2.9;
        } else if (category == "1 ★") {
          minRating = 1.0;
          maxRating = 1.9;
        } else {
          minRating = 0.0;
          maxRating = 5.0;
        }

        final ratingVendorsSnapshot = await FirebaseFirestore.instance
            .collection('vendor')
            .where('Rating', isGreaterThanOrEqualTo: minRating)
            .where('Rating', isLessThanOrEqualTo: maxRating)
            .get();

        setState(() {
          filteredVendors = ratingVendorsSnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
      }
    } catch (e) {
      print("Error fetching vendors by filter: $e");
    } finally {
      setState(() {
        isFetching = false;
      });
    }
  }

  Future<void> scrollToCategory(String category) async {
    setState(() {
      // Select or deselect the category
      if (selectedCategory == category) {
        selectedCategory = null;
        filteredVendors = allVendors; // Show all vendors if deselected
      } else {
        selectedCategory = category;
      }
    });

    // Optional: Scroll to the selected category in the horizontal ListView
    if (_categoriesScrollController.hasClients) {
      final index = categories.indexOf(category);
      final offset = index * 100.0; // Approximate width of each item
      _categoriesScrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    // Fetch vendors by filter
    if (selectedCategory != null) {
      await fetchVendorsByFilter(category);
    }

    // Scroll to the "All Vendors" section
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = allVendorsKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            "No user is logged in. Please log in to access recommendations.",
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
        ),
      );
    }
    final userId = user.uid;

    return Scaffold(
      //----------------------- App Bar-----------------------
      appBar: AppBar(
        backgroundColor: const Color(0xFFBF0000),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "HomeTouch",
              style: TextStyle(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            //----------------------- Search bar-----------------------
            SizedBox(
              width: screenWidth * 0.9,
              height: screenHeight * 0.06,
              child: TextField(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search, color: Colors.black54),
                  hintText: "Search...",
                  hintStyle: TextStyle(
                      color: Colors.black54, fontSize: screenWidth * 0.04),
                  contentPadding: EdgeInsets.all(screenWidth * 0.02),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ],
        ),
        //----------------------- menu and locationn icons-----------------------
        leading: Builder(
          builder: (context) {
            return Padding(
              padding: EdgeInsets.only(bottom: screenHeight * 0.07),
              child: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            );
          },
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(bottom: screenHeight * 0.07),
            child: IconButton(
              icon: const Icon(Icons.location_on_outlined, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ],
        toolbarHeight: screenHeight * 0.15,
      ),
      //----------------------- Body-----------------------
      body: Container(
        color: Colors.white,
        child: CustomScrollView(
          controller:
              _allVendorsScrollController, // Attach the scroll controller
          slivers: [
            // Tab Filters Section
            SliverPersistentHeader(
              pinned: true, // Ensures the header remains visible when scrolling
              delegate: _SliverAppBarDelegate(
                minHeight: 50.0, // Minimum height of the header
                maxHeight: 50.0, // Maximum height of the header
                child: Container(
                  color: Colors.white, // Background color of the filtering tabs
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.03,
                    vertical: screenHeight * 0.01,
                  ),
                  child: SizedBox(
                    height: 40, // Height of the filtering tabs
                    child: ListView.builder(
                      controller: _categoriesScrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return GestureDetector(
                          onTap: () async {
                            await scrollToCategory(category);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 8.0,
                            ),
                            decoration: BoxDecoration(
                              color: selectedCategory == category
                                  ? const Color(0xFFBF0000)
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Center(
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: selectedCategory == category
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: screenWidth * 0.035,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Promotion Container Section
            SliverToBoxAdapter(
              child: Center(
                child: Container(
                  width: screenWidth * 0.95,
                  height: screenHeight * 0.2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    border: Border.all(
                      color: Colors.white,
                      width: 1,
                    ),
                  ),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        child: Image.network(
                          images[index],
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

// Spacing After Promotion Section
            SliverToBoxAdapter(
              child: SizedBox(height: screenHeight * 0.02),
            ),

// Spacing After Promotion Section
            SliverToBoxAdapter(
              child: SizedBox(height: screenHeight * 0.02),
            ),

            // Food Vendor and Food Truck Filters Section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Home Vendor Filter
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isHomeVendorSelected = !isHomeVendorSelected;
                        });
                      },
                      child: Container(
                        width: screenWidth * 0.4,
                        height: screenHeight * 0.21,
                        decoration: BoxDecoration(
                          color: isHomeVendorSelected
                              ? Colors.grey[300]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(7.0),
                          image: const DecorationImage(
                            image:
                                NetworkImage('https://i.imgur.com/9cClf6J.png'),
                            fit: BoxFit.contain,
                          ),
                          border: Border.all(
                            color: isHomeVendorSelected
                                ? const Color(0xFFBF0000)
                                : Colors.transparent,
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6.0,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Padding(
                              padding:
                                  EdgeInsets.only(top: screenWidth * 0.325),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Text(
                                  "Home Vendor",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: screenWidth * 0.05,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Food Truck Filter
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isFoodTruckSelected = !isFoodTruckSelected;
                        });
                      },
                      child: Container(
                        width: screenWidth * 0.4,
                        height: screenHeight * 0.21,
                        decoration: BoxDecoration(
                          color: isFoodTruckSelected
                              ? Colors.grey[300]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(7.0),
                          image: const DecorationImage(
                            image:
                                NetworkImage('https://i.imgur.com/NO7NkOR.png'),
                            fit: BoxFit.contain,
                          ),
                          border: Border.all(
                            color: isFoodTruckSelected
                                ? const Color(0xFFBF0000)
                                : Colors.transparent,
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6.0,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: screenWidth * 0.3),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Text(
                                  "Food Truck",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: screenWidth * 0.05,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Spacing
            SliverToBoxAdapter(
              child: SizedBox(
                height: screenHeight * 0.03,
              ),
            ),

            // Categories Filter Section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                child: Text(
                  "Categories",
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: screenHeight * 0.18,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  children: [
                    _buildCategoryCard(
                        "Burger", "https://i.imgur.com/ZV72h1n.png"),
                    _buildCategoryCard(
                        "Pizza", "https://i.imgur.com/GfF6ETR.jpeg"),
                    _buildCategoryCard(
                        "Pasta", "https://i.imgur.com/9fcibiI.png"),
                    _buildCategoryCard(
                        "Arab", "https://i.imgur.com/V9w7Rn5.jpeg"),
                    _buildCategoryCard(
                        "Seafood", "https://i.imgur.com/9RDFums.png"),
                    _buildCategoryCard(
                        "Dessert", "https://i.imgur.com/Yblx4m1.jpeg"),
                    _buildCategoryCard(
                        "Drinks", "https://i.imgur.com/MZ1ADk7.jpeg"),
                    _buildCategoryCard(
                        "Breakfast", "https://i.imgur.com/ICe9P88.jpeg"),
                  ],
                ),
              ),
            ),

            // Spacing before Suggestions Section
            SliverToBoxAdapter(
              child: SizedBox(height: screenHeight * 0.02),
            ),

            // Suggestions Section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                child: Text(
                  "Suggestions",
                  style: TextStyle(
                    fontSize: screenWidth * 0.065,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchRecommendedVendors(userId), // Pass Customer_ID
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                        child: Text(
                          "An error occurred while fetching recommendations.",
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                        child: Text(
                          "No recommendations available.",
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    );
                  }

                  final recommendedVendors = snapshot.data!;

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: recommendedVendors.length,
                    itemBuilder: (context, index) {
                      final vendor = recommendedVendors[index];

                      return _buildVendorCard(
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                        title: vendor['Name'] ?? "Unknown",
                        rating: vendor['Rating']?.toString() ?? "0.0",
                        deliveryTime: "30 mins",
                        price: "BHD 0.600",
                        imageUrl: vendor['Logo']?.isNotEmpty == true
                            ? vendor['Logo']
                            : 'https://via.placeholder.com/150', // Fallback image
                        isFavorite: false,
                        onFavoriteToggle: (newValue) {
                          setState(() {
                            // Handle favorite toggle logic if needed
                          });
                        },
                        onCardTap: () {
                          print("Tapped on ${vendor['Name']}");
                        },
                      );
                    },
                  );
                },
              ),
            ),

            // All Vendors Section
            SliverToBoxAdapter(
              key: allVendorsKey, // Attach the GlobalKey here
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                child: Text(
                  "All",
                  style: TextStyle(
                    fontSize: screenWidth * 0.065,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            filteredVendors.isEmpty
                ? SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                        child: Text(
                          "No vendors found!",
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final vendor = filteredVendors[index];
                        return _buildAllCard(
                          index: index,
                          screenWidth: screenWidth,
                          screenHeight: screenHeight,
                          title: vendor['Name'] ?? "Unknown",
                          rating: vendor['Rating']?.toString() ?? "0.0",
                          deliveryTime: "30 mins",
                          price: "BHD 0.600",
                          imageUrl: vendor['Logo'] ??
                              'https://via.placeholder.com/150',
                          isFavorite: false,
                          onFavoriteToggle: (newValue) {
                            setState(() {
                              // Handle favorite toggle logic
                            });
                          },
                          onCardTap: () {
                            print("Tapped on ${vendor['Name']}");
                          },
                        );
                      },
                      childCount: filteredVendors.length,
                    ),
                  ),
          ],
        ),
      ),

      //----------------------- Drawer (for menu icon)-----------------------
      // drawer: DrawerScreen(
      //   selectedIndex: currentMenuIndex,
      //   onItemTapped: (index) {
      //     setState(() {
      //       currentMenuIndex = index;
      //     });
      //   },
      // ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: trackNavBarIcons,
        selectedItemColor: const Color(0xFFBF0000),
        unselectedItemColor: Colors.black54,
        onTap: (index) {
          setState(() {
            trackNavBarIcons = index;
          });
        },
        selectedLabelStyle: const TextStyle(fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: "Favorite"),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: "Cart"),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Orders"),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle), label: "Account"),
        ],
      ),
    );
  }
}

//-----------------------Category Widget-----------------------
Widget _buildCategoryCard(String category, String imageUrl) {
  return GestureDetector(
    onTap: () {
      // Placeholder for future functionality
      // Navigate to category-specific page or perform action
    },
    child: Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Prevent overflow by adjusting size
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7.0),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Flexible(
            child: Text(
              category,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis, // Prevent overflow by truncating
              maxLines: 1, // Limit the number of lines to avoid overflow
              textAlign: TextAlign.center, // Center-align the category name
            ),
          ),
        ],
      ),
    ),
  );
}

//-----------------------Suggestions Widget-----------------------
Widget _buildVendorCard({
  required double screenWidth,
  required double screenHeight,
  required String title,
  required String rating,
  required String deliveryTime,
  required String price,
  required String imageUrl,
  required bool isFavorite,
  required Function(bool) onFavoriteToggle,
  required Function() onCardTap,
}) {
  return Padding(
    padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04, vertical: screenHeight * 0.01),
    child: Stack(
      children: [
        GestureDetector(
          onTap: onCardTap,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7.0),
            ),
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.00),
              child: Row(
                children: [
                  // Image Section
                  Container(
                    width: screenWidth * 0.2,
                    height: screenHeight * 0.1,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7.0),
                      image: DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.04),

                  // Text Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              size: 16, color: Color(0xFFBF0000)),
                          SizedBox(width: screenWidth * 0.01),
                          Text(" $rating"),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 16, color: Colors.black54),
                          SizedBox(width: screenWidth * 0.01),
                          Text(" $deliveryTime "),
                          const Icon(Icons.delivery_dining,
                              size: 16, color: Color(0xFFBF0000)),
                          SizedBox(width: screenWidth * 0.01),
                          Text(" $price"),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Heart Icon
        Positioned(
          top: screenHeight * 0.01,
          right: screenWidth * 0.04,
          child: GestureDetector(
            onTap: () {
              onFavoriteToggle(!isFavorite);
            },
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.grey,
            ),
          ),
        ),
      ],
    ),
  );
}

//-----------------------All restaurant Widget-----------------------
Widget _buildAllCard({
  required int index,
  required double screenWidth,
  required double screenHeight,
  required String title,
  required String rating,
  required String deliveryTime,
  required String price,
  required String imageUrl,
  required bool isFavorite,
  required Function(bool) onFavoriteToggle,
  required Function() onCardTap,
}) {
  return Padding(
    padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04, vertical: screenHeight * 0.01),
    child: Stack(
      children: [
        GestureDetector(
          onTap: onCardTap,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7.0),
            ),
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.00),
              child: Row(
                children: [
                  // Image Section - All restaurant
                  Container(
                    width: screenWidth * 0.2,
                    height: screenHeight * 0.1,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7.0),
                      image: DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.04),

                  // Text Section - All restaurant
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              size: 16, color: Color(0xFFBF0000)),
                          SizedBox(width: screenWidth * 0.01),
                          Text(" $rating"),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 16, color: Colors.black54),
                          SizedBox(width: screenWidth * 0.01),
                          Text(" $deliveryTime "),
                          const Icon(Icons.delivery_dining,
                              size: 16, color: Color(0xFFBF0000)),
                          SizedBox(width: screenWidth * 0.01),
                          Text(" $price"),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Heart Icon - All restaurant
        Positioned(
          top: screenHeight * 0.01,
          right: screenWidth * 0.04,
          child: GestureDetector(
            onTap: () {
              onFavoriteToggle(!isFavorite);
            },
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.grey,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
