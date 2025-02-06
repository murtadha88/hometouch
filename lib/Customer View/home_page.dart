import 'package:flutter/material.dart';
import 'package:hometouch/Customer%20View/acoount_page.dart';
import 'package:hometouch/Customer%20View/cart_page2.dart';
import 'package:hometouch/Customer%20View/favorite_page.dart';
// import 'package:hometouch/Customer%20View/acoount_page.dart';
// // import 'package:hometouch/Customer%20View/cart_page.dart';
// import 'package:hometouch/Customer%20View/favorite_page.dart';
import 'dart:async';
import 'side_bar.dart';
import 'address_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'menu_page.dart';

class HomeTouchScreen extends StatefulWidget {
  final int initialIndex;
  const HomeTouchScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeTouchScreen> createState() => _HomeTouchScreenState();
}

//----------------------- Variables-----------------------
class _HomeTouchScreenState extends State<HomeTouchScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = "";
  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();
  FocusNode _searchFocusNode = FocusNode();

  // bool isFavorite2 = false;
  final Set<String> favoriteVendors = {};

  bool isHomeVendorSelected = false;
  bool isFoodTruckSelected = false;
  PageController _pageController = PageController();
  int _currentIndex = 0;
  int currentMenuIndex = 0;
  int _selectedIndex = 0; // Keep track of the selected item in the drawer

  final GlobalKey allVendorsKey = GlobalKey();

  final List<String> categories = [
    "Trending",
    "5 ★",
    "4 ★",
    "3 ★",
    "2 ★",
    "1 ★",
  ];

  String? selectedCategory;
  String? selectedCategoryFilter;
  final ScrollController _categoriesScrollController = ScrollController();
  final ScrollController _allVendorsScrollController = ScrollController();

  List<Map<String, dynamic>> allVendors = [];
  List<Map<String, dynamic>> filteredVendors = [];
  List<String> images = [];
  bool isFetching = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchAllVendors();
    fetchPromotions();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userId = user.uid; // Declare userId here
      fetchFavoriteVendors(userId); // Use the userId when calling the function
    }

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
    _searchController.dispose();
    _searchFocusNode.dispose();
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

  Stream<List<Map<String, dynamic>>> searchVendors(String query) {
    if (query.isEmpty) {
      return Stream.value([]);
    } else {
      String formattedQuery =
          query[0].toUpperCase() + query.substring(1).toLowerCase();

      return _firestore
          .collection('vendor')
          .where('Name', isGreaterThanOrEqualTo: formattedQuery)
          .where('Name', isLessThanOrEqualTo: formattedQuery + '\uf8ff')
          .snapshots()
          .map((snapshot) {
        List<Map<String, dynamic>> vendorList = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        return vendorList;
      });
    }
  }

  Future<void> fetchPromotions() async {
    setState(() {
      isFetching = true;
    });

    try {
      final now = DateTime.now();
      final promotionsQuery = await _firestore
          .collection('promotion')
          .where('Start_Date', isLessThanOrEqualTo: now)
          .where('End_Date', isGreaterThanOrEqualTo: now)
          .get();

      setState(() {
        images = promotionsQuery.docs.map((doc) {
          final data = doc.data();
          return data['Image'] as String? ?? ''; // Safe cast to String
        }).toList();
      });
    } catch (e) {
      print("Error fetching promotions: $e");
    } finally {
      setState(() {
        isFetching = false;
      });
    }
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
        filteredVendors =
            allVendors; // Initialize filteredVendors with all vendors
      });
    } catch (e) {
      print("Error fetching vendors: $e");
    }
  }

  Future<void> applyCombinedFilters() async {
    setState(() {
      isFetching = true;
    });

    try {
      List<Map<String, dynamic>> filtered = allVendors;

      // Apply vendor type filter
      if (isHomeVendorSelected) {
        filtered = filtered
            .where((vendor) => vendor['Vendor_Type'] == 'Homemade')
            .toList();
      } else if (isFoodTruckSelected) {
        filtered = filtered
            .where((vendor) => vendor['Vendor_Type'] == 'Food Truck')
            .toList();
      }

      // Apply category filter
      if (selectedCategoryFilter != null) {
        filtered = filtered
            .where((vendor) => vendor['Category'] == selectedCategoryFilter)
            .toList();
      }

      // Apply rating filter
      if (selectedCategory != null) {
        if (selectedCategory == "Trending") {
          // Fetch trending vendors (you can implement this logic separately)
          final ordersSnapshot =
              await FirebaseFirestore.instance.collection('order').get();

          final Map<String, int> vendorOrderCount = {};
          for (var orderDoc in ordersSnapshot.docs) {
            final vendorRef = orderDoc['Vendor_ID'] as DocumentReference?;
            if (vendorRef != null) {
              final vendorId = vendorRef.id;
              vendorOrderCount[vendorId] =
                  (vendorOrderCount[vendorId] ?? 0) + 1;
            }
          }

          final sortedVendors = vendorOrderCount.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final topVendorIds =
              sortedVendors.take(10).map((entry) => entry.key).toList();

          filtered = filtered
              .where((vendor) => topVendorIds.contains(vendor['id']))
              .toList();
        } else {
          double minRating = 0.0;
          double maxRating = 5.0;

          if (selectedCategory == "5 ★") {
            minRating = 5.0;
            maxRating = 5.0;
          } else if (selectedCategory == "4 ★") {
            minRating = 4.0;
            maxRating = 4.9;
          } else if (selectedCategory == "3 ★") {
            minRating = 3.0;
            maxRating = 3.9;
          } else if (selectedCategory == "2 ★") {
            minRating = 2.0;
            maxRating = 2.9;
          } else if (selectedCategory == "1 ★") {
            minRating = 1.0;
            maxRating = 1.9;
          }

          filtered = filtered
              .where((vendor) =>
                  vendor['Rating'] >= minRating &&
                  vendor['Rating'] <= maxRating)
              .toList();
        }
      }

      // Update filteredVendors
      setState(() {
        filteredVendors = filtered;
      });

      // Scroll to "All Vendors" section
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
    } catch (e) {
      print("Error applying combined filters: $e");
    } finally {
      setState(() {
        isFetching = false;
      });
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

  Future<void> filterVendorsByType(String type) async {
    setState(() {
      // Toggle the filter state based on the current selection
      if (type == "Homemade") {
        isHomeVendorSelected = !isHomeVendorSelected;
        isFoodTruckSelected = false; // Deselect the other filter
      } else if (type == "Food Truck") {
        isFoodTruckSelected = !isFoodTruckSelected;
        isHomeVendorSelected = false; // Deselect the other filter
      }
    });

    // Apply combined filters
    await applyCombinedFilters();
  }

  Future<void> filterVendorsByCategory(String category) async {
    setState(() {
      // Toggle the category filter
      if (selectedCategoryFilter == category) {
        selectedCategoryFilter = null; // Deselect if already selected
      } else {
        selectedCategoryFilter = category;
      }
    });

    // Apply combined filters
    await applyCombinedFilters();
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
    await applyCombinedFilters();
  }

  Future<void> _toggleFavorite(String vendorId, String userId) async {
    if (vendorId.isEmpty) {
      return;
    }

    try {
      final userRef =
          FirebaseFirestore.instance.collection('Customer').doc(userId);
      final favoriteRef = userRef.collection('favorite').doc(vendorId);

      setState(() {
        if (favoriteVendors.contains(vendorId)) {
          favoriteVendors.remove(vendorId);
          favoriteRef.delete();
        } else {
          favoriteVendors.add(vendorId);
          favoriteRef.set({'Vendor_ID': vendorId, 'Type': 'vendor'});
        }
      });
    } catch (e) {
      print("Error toggling favorite: $e");
    }
  }

  Future<void> fetchFavoriteVendors(String userId) async {
    try {
      final favoritesSnapshot = await FirebaseFirestore.instance
          .collection('Customer')
          .doc(userId)
          .collection('favorite')
          .get();

      setState(() {
        favoriteVendors.clear();
        favoriteVendors.addAll(favoritesSnapshot.docs.map((doc) => doc.id));
      });
    } catch (e) {
      print("Error fetching favorite vendors: $e");
    }
  }

  Future<bool> _onWillPop() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return false;
    }

    return true;
  }

  Future<void> _navigateToFoodMenu(String vendorId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodMenuPage(vendorId: vendorId),
      ),
    );

    if (mounted) {
      setState(() {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          fetchFavoriteVendors(userId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
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
                AnimatedContainer(
                  duration:
                      const Duration(milliseconds: 300), // Smooth transition
                  width: screenWidth * 0.9,
                  height: screenHeight * 0.06,
                  child: TextField(
                    focusNode: _searchFocusNode,
                    controller: _searchController,
                    onTap: () {
                      if (!_isSearching) {
                        setState(() {
                          _isSearching =
                              true; // Switch to search mode only when the search bar is tapped
                        });
                      }
                    },
                    onChanged: (query) {
                      setState(() {
                        _searchQuery =
                            query; // Update the search query as the user types
                      });
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: _isSearching
                          ? IconButton(
                              icon: Icon(Icons.arrow_back),
                              onPressed: () {
                                setState(() {
                                  _isSearching = false; // Return to home page
                                  _searchQuery =
                                      ''; // Clear the text inside the search bar
                                  _searchController
                                      .clear(); // Clear the TextField's text
                                });
                                _searchFocusNode.unfocus(); // Close keyboard
                              },
                            )
                          : Icon(Icons.search, color: Colors.black54),
                      hintText: "Search...",
                      hintStyle: TextStyle(
                          color: Colors.black54, fontSize: screenWidth * 0.04),
                      contentPadding: EdgeInsets.all(screenWidth * 0.01),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            leading: Builder(
              builder: (context) {
                return Padding(
                  padding: EdgeInsets.only(bottom: screenHeight * 0.07),
                  child: IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () {
                      FocusScope.of(context).unfocus();
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
                  icon: const Icon(Icons.location_on_outlined,
                      color: Colors.white),
                  onPressed: () {
                    // Show the Address Dialog as a BottomSheet
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true, // Allow it to expand as needed
                      backgroundColor:
                          Colors.transparent, // Transparent background
                      builder: (BuildContext context) {
                        return AddressDialog(
                          screenWidth: screenWidth,
                          screenHeight: screenHeight,
                          onClose: () {
                            Navigator.pop(
                                context); // Close the bottom sheet when the close button is pressed
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
            toolbarHeight: screenHeight * 0.15,
          ),
          body: _isSearching
              ? _buildSearchPage()
              : _buildMainPage(screenWidth, screenHeight),
          drawer: DrawerScreen(
            selectedIndex: _selectedIndex,
            onItemTapped:
                _onItemTapped, // Pass the onItemTapped function to the drawer
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
                child: const Icon(Icons.shopping_cart,
                    color: Colors.white, size: 30),
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
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
        ));
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

  Widget _buildSearchPage() {
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

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: searchVendors(_searchQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error fetching data"));
                }

                final vendors = snapshot.data ?? [];
                if (vendors.isEmpty) {
                  return Center(child: Text("No results found"));
                }

                return ListView.builder(
                  itemCount: vendors.length,
                  itemBuilder: (context, index) {
                    final vendor = vendors[index];
                    final vendorId = vendor['id'] ?? '';

                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: _buildAllVendorCard(
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                        title: vendor['Name'] ?? "Unknown",
                        rating: vendor['Rating']?.toString() ?? "0.0",
                        price: "BHD 0.600",
                        imageUrl: vendor['Logo']?.isNotEmpty == true
                            ? vendor['Logo']
                            : 'https://via.placeholder.com/150',
                        onCardTap: () async {
                          if (vendorId.isNotEmpty) {
                            _navigateToFoodMenu(vendorId);
                          } else {
                            print("Error: Vendor ID is empty");
                          }
                        },
                        vendorId: vendorId, // Pass the validated vendor ID
                        userId: userId,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainPage(double screenWidth, double screenHeight) {
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
    return Container(
      color: Colors.white,
      child: CustomScrollView(
        controller: _allVendorsScrollController,
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              minHeight: 50.0,
              maxHeight: 50.0,
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.03,
                  vertical: screenHeight * 0.01,
                ),
                child: SizedBox(
                  height: 40,
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
                child: isFetching || images.isEmpty
                    ? Text('No Promotions')
                    : PageView.builder(
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
          SliverToBoxAdapter(
            child: SizedBox(height: screenHeight * 0.02),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () async {
                      await filterVendorsByType("Homemade");
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
                          color: Colors.transparent,
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
                            padding: EdgeInsets.only(top: screenWidth * 0.325),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Text(
                                "Home Vendor",
                                style: TextStyle(
                                  color: isHomeVendorSelected
                                      ? Color(0xFFBF0000)
                                      : Colors.black,
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
                  GestureDetector(
                    onTap: () async {
                      await filterVendorsByType("Food Truck");
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
                          color: Colors.transparent,
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
                                  color: isFoodTruckSelected
                                      ? Color(0xFFBF0000)
                                      : Colors.black,
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
          SliverToBoxAdapter(
            child: SizedBox(
              height: screenHeight * 0.03,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              child: Text(
                "Categories",
                style: TextStyle(
                  fontSize: screenWidth * 0.06,
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
                    category: "Burger",
                    imageUrl: "https://i.imgur.com/ZV72h1n.png",
                    selectedCategoryFilter: selectedCategoryFilter,
                    onCategoryTap: filterVendorsByCategory,
                  ),
                  _buildCategoryCard(
                    category: "Pizza",
                    imageUrl: "https://i.imgur.com/h5FfoBJ.png",
                    selectedCategoryFilter: selectedCategoryFilter,
                    onCategoryTap: filterVendorsByCategory,
                  ),
                  _buildCategoryCard(
                    category: "Pasta",
                    imageUrl: "https://i.imgur.com/9fcibiI.png",
                    selectedCategoryFilter: selectedCategoryFilter,
                    onCategoryTap: filterVendorsByCategory,
                  ),
                  _buildCategoryCard(
                    category: "Arab",
                    imageUrl: "https://i.imgur.com/GeFNHwg.png",
                    selectedCategoryFilter: selectedCategoryFilter,
                    onCategoryTap: filterVendorsByCategory,
                  ),
                  _buildCategoryCard(
                    category: "Seafood",
                    imageUrl: "https://i.imgur.com/9RDFums.png",
                    selectedCategoryFilter: selectedCategoryFilter,
                    onCategoryTap: filterVendorsByCategory,
                  ),
                  _buildCategoryCard(
                    category: "Dessert",
                    imageUrl: "https://i.imgur.com/balQfIA.png",
                    selectedCategoryFilter: selectedCategoryFilter,
                    onCategoryTap: filterVendorsByCategory,
                  ),
                  _buildCategoryCard(
                    category: "Drinks",
                    imageUrl: "https://i.imgur.com/MZ1ADk7.jpeg",
                    selectedCategoryFilter: selectedCategoryFilter,
                    onCategoryTap: filterVendorsByCategory,
                  ),
                  _buildCategoryCard(
                    category: "Breakfast",
                    imageUrl: "https://i.imgur.com/pyWuh4o.png",
                    selectedCategoryFilter: selectedCategoryFilter,
                    onCategoryTap: filterVendorsByCategory,
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: screenHeight * 0.02),
          ),
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
              future: fetchRecommendedVendors(userId),
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
                    final vendorId = vendor['id'];

                    return _buildSuggestionVendorCard(
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                      title: vendor['Name'] ?? "Unknown",
                      rating: vendor['Rating']?.toString() ?? "0.0",
                      price: "BHD 0.600",
                      imageUrl: vendor['Logo']?.isNotEmpty == true
                          ? vendor['Logo']
                          : 'https://via.placeholder.com/150',
                      onCardTap: () async {
                        if (vendorId.isNotEmpty) {
                          _navigateToFoodMenu(vendorId);
                        } else {
                          print("Error: Vendor ID is empty");
                        }
                      },
                      vendorId: vendor['id'],
                      userId: userId,
                    );
                  },
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            key: allVendorsKey,
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
                      final vendorId = vendor['id'];
                      return _buildAllVendorCard(
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                        title: vendor['Name'] ?? "Unknown",
                        rating: vendor['Rating']?.toString() ?? "0.0",
                        price: "BHD 0.600",
                        imageUrl: vendor['Logo']?.isNotEmpty == true
                            ? vendor['Logo']
                            : 'https://via.placeholder.com/150',
                        onCardTap: () async {
                          if (vendorId.isNotEmpty) {
                            _navigateToFoodMenu(vendorId);
                          } else {
                            print("Error: Vendor ID is empty");
                          }
                        },
                        vendorId: vendor['id'],
                        userId: userId,
                      );
                    },
                    childCount: filteredVendors.length,
                  ),
                ),
        ],
      ),
    );
  }

  // This is where the favorite toggle is handled in the card widget
  Widget _buildSuggestionVendorCard({
    required double screenWidth,
    required double screenHeight,
    required String title,
    required String rating,
    required String price,
    required String imageUrl,
    required Function() onCardTap,
    required String vendorId,
    required String userId,
  }) {
    final isFavorite = favoriteVendors.contains(vendorId);
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
              color: Colors.grey[200],
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.00),
                child: Row(
                  children: [
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
          Positioned(
            top: screenHeight * 0.01,
            right: screenWidth * 0.04,
            child: GestureDetector(
              onTap: () async {
                await _toggleFavorite(vendorId, userId); // Toggle favorite
              },
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Color(0xFFBF0000) : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllVendorCard({
    required double screenWidth,
    required double screenHeight,
    required String title,
    required String rating,
    required String price,
    required String imageUrl,
    required Function() onCardTap,
    required String vendorId,
    required String userId,
  }) {
    final isFavorite =
        favoriteVendors.contains(vendorId); // Check if vendor is favorited
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.01,
      ),
      child: Stack(
        children: [
          GestureDetector(
            onTap: onCardTap,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7.0),
              ),
              color: Colors.white,
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.00),
                child: Row(
                  children: [
                    // Vendor image and details
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
          // Favorite icon
          Positioned(
            top: screenHeight * 0.01,
            right: screenWidth * 0.04,
            child: GestureDetector(
              onTap: () async {
                await _toggleFavorite(vendorId, userId); // Toggle favorite
              },
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Color(0xFFBF0000) : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildCategoryCard({
  required String category,
  required String imageUrl,
  required String? selectedCategoryFilter,
  required Function(String) onCategoryTap,
}) {
  return GestureDetector(
    onTap: () async {
      await onCategoryTap(category);
    },
    child: Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
              color: selectedCategoryFilter == category
                  ? Colors.grey[300]
                  : Colors.grey[100],
              border: Border.all(
                color: Colors.transparent,
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 2.0,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8.0),
          Flexible(
            child: Text(
              category,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selectedCategoryFilter == category
                    ? const Color(0xFFBF0000)
                    : Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
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
