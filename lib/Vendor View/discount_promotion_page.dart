import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

const Color primaryRed = Color(0xFFBF0000);

class PromotionDiscountPage extends StatefulWidget {
  const PromotionDiscountPage({super.key});

  @override
  _PromotionDiscountPageState createState() => _PromotionDiscountPageState();
}

class _PromotionDiscountPageState extends State<PromotionDiscountPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _promoStartDateController =
      TextEditingController();
  final TextEditingController _promoEndDateController = TextEditingController();
  File? _promoUploadedFile1;
  File? _promoUploadedFile2;
  String? _promoImageUrl;
  DateTime? _promoStartDate;
  DateTime? _promoEndDate;

  Future<void> _uploadPromoImage(File image, bool isFirst) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("https://api.imgur.com/3/upload"),
      );
      request.headers['Authorization'] = 'Client-ID ca25aec45d48f73';
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseData);
      if (jsonResponse['success'] == true) {
        setState(() {
          _promoImageUrl = jsonResponse['data']['link'];
        });
      }
    } catch (e) {
      print("Error uploading promo image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to upload image'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickPromoImage(bool isFirst) async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      setState(() {
        if (isFirst) {
          _promoUploadedFile1 = imageFile;
        } else {
          _promoUploadedFile2 = imageFile;
        }
      });
      await _uploadPromoImage(imageFile, isFirst);
    }
  }

  Future<void> _selectPromoDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _promoStartDate = picked;
          _promoStartDateController.text = "${picked.toLocal()}".split(' ')[0];
        } else {
          _promoEndDate = picked;
          _promoEndDateController.text = "${picked.toLocal()}".split(' ')[0];
        }
      });
    }
  }

  double get _totalPromoCost {
    if (_promoStartDate == null || _promoEndDate == null) return 0.0;
    final difference = _promoEndDate!.difference(_promoStartDate!).inDays;
    return difference >= 0 ? difference + 1 : 0.0;
  }

  Future<void> _savePromotion() async {
    if (_promoStartDate == null || _promoEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select dates')),
      );
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('promotion').add({
        'Vendor_ID': user.uid,
        'Start_Date': _promoStartDate,
        'End_Date': _promoEndDate,
        'Image': _promoImageUrl,
        'Total_Cost': _totalPromoCost,
      });
      setState(() {
        _promoStartDateController.clear();
        _promoEndDateController.clear();
        _promoUploadedFile1 = null;
        _promoUploadedFile2 = null;
        _promoImageUrl = null;
        _promoStartDate = null;
        _promoEndDate = null;
      });
      _showPromoSuccessDialog();
      Future.delayed(const Duration(seconds: 3), () {
        Navigator.pop(context);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showPromoSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        return AlertDialog(
          backgroundColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.03, horizontal: screenWidth * 0.05),
          title: Container(
            padding: EdgeInsets.all(screenWidth * 0.05),
            decoration: const BoxDecoration(
              color: primaryRed,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check,
                color: Colors.white, size: screenWidth * 0.12),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Successful Promotion Added',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Container(
                alignment: Alignment.center,
                child: Text(
                  'Please wait. You will be directed back',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.w300,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              CircularProgressIndicator(
                valueColor: const AlwaysStoppedAnimation<Color>(primaryRed),
              ),
            ],
          ),
        );
      },
    );
  }

  final TextEditingController _discountPercentageController =
      TextEditingController();
  final TextEditingController _discountStartDateController =
      TextEditingController();
  final TextEditingController _discountEndDateController =
      TextEditingController();
  DateTime? _discountStartDate;
  DateTime? _discountEndDate;
  final List<Map<String, dynamic>> _vendorProducts = [];
  final Set<String> _selectedProductIds = {};

  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _categoryKeys = {};
  String _selectedCategory = "All";
  Map<String, List<Map<String, dynamic>>> _categorizedProducts = {};

  late Future<Map<String, List<Map<String, dynamic>>>> _vendorProductsFuture;

  Future<Map<String, List<Map<String, dynamic>>>> _getVendorProducts() async {
    final Map<String, List<Map<String, dynamic>>> categorizedProducts = {};
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return categorizedProducts;

    _vendorProducts.clear();

    QuerySnapshot catSnapshot = await _firestore
        .collection('vendor')
        .doc(user.uid)
        .collection('category')
        .get();

    for (var catDoc in catSnapshot.docs) {
      String categoryName = catDoc['Name'] ?? "Unnamed Category";
      String categoryId = catDoc.id;

      QuerySnapshot prodSnapshot =
          await catDoc.reference.collection('products').get();

      List<Map<String, dynamic>> products = [];
      for (var prodDoc in prodSnapshot.docs) {
        Map<String, dynamic> data = prodDoc.data() as Map<String, dynamic>;
        data["id"] = prodDoc.id;
        data["categoryId"] = categoryId;
        products.add(data);
      }

      categorizedProducts[categoryName] = products;
      _categoryKeys[categoryName] = GlobalKey();

      _vendorProducts.addAll(products);
    }

    categorizedProducts["All"] =
        categorizedProducts.values.expand((products) => products).toList();

    return categorizedProducts;
  }

  Future<void> _applyDiscount() async {
    double discountPercentage =
        double.tryParse(_discountPercentageController.text) ?? 0.0;
    if (discountPercentage <= 0 ||
        _discountStartDate == null ||
        _discountEndDate == null ||
        _selectedProductIds.isEmpty) {
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      for (var product in _vendorProducts) {
        if (_selectedProductIds.contains(product["id"])) {
          print(product["categoryId"]);
          DocumentReference prodRef = _firestore
              .collection('vendor')
              .doc(user.uid)
              .collection('category')
              .doc(product["categoryId"])
              .collection('products')
              .doc(product["id"]);
          DocumentSnapshot prodSnap = await prodRef.get();
          double originalPrice =
              (prodSnap.data() as Map<String, dynamic>)['Price'] ?? 0.0;
          double discountedPrice =
              originalPrice - (originalPrice * discountPercentage / 100);
          await prodRef.update({
            'Discount_Price': discountedPrice,
            'Discount_Start_Date': _discountStartDate,
            'Discount_End_Date': _discountEndDate,
            'Discount_Percentage': discountPercentage,
          });
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Discount applied successfully')),
      );
      setState(() {
        _selectedProductIds.clear();
        _discountPercentageController.clear();
        _discountStartDateController.clear();
        _discountEndDateController.clear();
        _discountStartDate = null;
        _discountEndDate = null;
      });
    } catch (e) {
      print("Error applying discount: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error applying discount: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _selectDiscountDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _discountStartDate = picked;
          _discountStartDateController.text =
              "${picked.toLocal()}".split(' ')[0];
        } else {
          _discountEndDate = picked;
          _discountEndDateController.text = "${picked.toLocal()}".split(' ')[0];
        }
      });
    }
  }

  Widget _buildDiscountedProductsList() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
      future: _vendorProductsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: primaryRed));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No products available"));
        }

        _categorizedProducts = snapshot.data!;
        final categories = _categorizedProducts.keys.toList();

        return Column(
          children: [
            SizedBox(
              height: screenHeight * 0.06,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return GestureDetector(
                    onTap: () => _scrollToCategory(category),
                    child: Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                      padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenHeight * 0.01),
                      decoration: BoxDecoration(
                        color: _selectedCategory == category
                            ? primaryRed
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          category,
                          style: TextStyle(
                            color: _selectedCategory == category
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
            const SizedBox(height: 16),
            Scrollbar(
              controller: _scrollController,
              child: ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.only(bottom: screenHeight * 0.14),
                itemCount: _categorizedProducts.keys.length,
                itemBuilder: (context, index) {
                  final category = _categorizedProducts.keys.elementAt(index);
                  final products = _categorizedProducts[category]!;

                  return Column(
                    key: _categoryKeys[category],
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenHeight * 0.015),
                        child: Text(
                          "$category (${products.length})",
                          style: TextStyle(
                              fontSize: screenWidth * 0.05,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: products.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.8,
                        ),
                        itemBuilder: (context, itemIndex) {
                          final item = products[itemIndex];
                          bool isSelected =
                              _selectedProductIds.contains(item["id"]);

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedProductIds.remove(item["id"]);
                                } else {
                                  _selectedProductIds.add(item["id"]);
                                }
                              });
                            },
                            child: Card(
                              color: isSelected ? primaryRed : Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      width: screenWidth * 0.479,
                                      height: screenHeight * 0.135,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(15)),
                                      ),
                                      child: (item["Image"] != null &&
                                              (item["Image"] as String)
                                                  .trim()
                                                  .isNotEmpty &&
                                              (item["Image"] as String)
                                                  .startsWith("http"))
                                          ? Image.network(
                                              item["Image"],
                                              fit: BoxFit.cover,
                                              width: screenWidth * 0.479,
                                              height: screenHeight * 0.135,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return const Center(
                                                  child: Icon(
                                                    Icons.fastfood,
                                                    color: Colors.grey,
                                                    size: 50,
                                                  ),
                                                );
                                              },
                                            )
                                          : const Center(
                                              child: Icon(
                                                Icons.fastfood,
                                                color: Colors.grey,
                                                size: 50,
                                              ),
                                            ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      item["Name"] ?? "No Name",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0, vertical: 4.0),
                                    child: _buildPriceDisplay(item),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _scrollToCategory(String category) {
    if (category == "All") {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      final key = _categoryKeys[category];
      if (key != null && key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
    setState(() {
      _selectedCategory = category;
    });
  }

  @override
  void initState() {
    super.initState();
    _vendorProductsFuture = _getVendorProducts();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
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
              'Promotions & Discounts',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: screenWidth * 0.06,
              ),
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: primaryRed,
            labelColor: primaryRed,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: "Promotion"),
              Tab(text: "Discount"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: EdgeInsets.all(screenWidth * 0.04),
              children: [
                Text("Upload",
                    style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: screenHeight * 0.015),
                _buildUploadCard(isFirst: true),
                SizedBox(height: screenHeight * 0.02),
                Text("Promotion Dates",
                    style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: screenHeight * 0.015),
                TextField(
                  controller: _promoStartDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: "Select Start Date",
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(screenWidth * 0.02)),
                    suffixIcon: IconButton(
                      icon:
                          Icon(Icons.calendar_today, size: screenWidth * 0.06),
                      onPressed: () => _selectPromoDate(true),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                TextField(
                  controller: _promoEndDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: "Select End Date",
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(screenWidth * 0.02)),
                    suffixIcon: IconButton(
                      icon:
                          Icon(Icons.calendar_today, size: screenWidth * 0.06),
                      onPressed: () => _selectPromoDate(false),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),
                _buildSummaryRow(),
                SizedBox(height: screenHeight * 0.03),
                ElevatedButton(
                  onPressed: _savePromotion,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: primaryRed,
                      padding:
                          EdgeInsets.symmetric(vertical: screenHeight * 0.02)),
                  child: Text("Set Promotion",
                      style: TextStyle(
                          color: Colors.white, fontSize: screenWidth * 0.045)),
                ),
              ],
            ),
            Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.only(
                      bottom: screenHeight * 0.2, top: screenHeight * 0.02),
                  child: _buildDiscountedProductsList(),
                ),
                Positioned(
                  left: screenWidth * 0.04,
                  right: screenWidth * 0.04,
                  bottom: screenHeight * 0.02,
                  child: _buildDiscountInput(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard({required bool isFirst}) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final file = isFirst ? _promoUploadedFile1 : _promoUploadedFile2;
    return InkWell(
      onTap: () => _pickPromoImage(isFirst),
      child: Container(
        height: screenHeight * 0.2,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          color: Colors.grey.shade100,
        ),
        child: file != null
            ? Image.file(file, fit: BoxFit.cover)
            : Center(
                child: Text("Click to Upload Image",
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: screenWidth * 0.04)),
              ),
      ),
    );
  }

  Widget _buildSummaryRow() {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(screenWidth * 0.03)),
      child: Column(
        children: [
          _buildSummaryLine("Total Days", "${_totalPromoCost.toInt()} Days"),
          Divider(),
          _buildSummaryLine("Total Cost", "$_totalPromoCost BHD", isBold: true),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(String label, String value, {bool isBold = false}) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: screenWidth * 0.04)),
          Text(value,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: screenWidth * 0.04)),
        ],
      ),
    );
  }

  Widget _buildDiscountInput() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(screenWidth * 0.1),
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(screenWidth * 0.1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _discountStartDateController,
              readOnly: true,
              decoration: InputDecoration(
                hintText: "Discount Start Date",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.1),
                ),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.015),
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_today, size: screenWidth * 0.06),
                  onPressed: () => _selectDiscountDate(true),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.015),
            TextField(
              controller: _discountEndDateController,
              readOnly: true,
              decoration: InputDecoration(
                hintText: "Discount End Date",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.1),
                ),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.015),
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_today, size: screenWidth * 0.06),
                  onPressed: () => _selectDiscountDate(false),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.015),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _discountPercentageController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Discount %",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.1),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenHeight * 0.015),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),
                ElevatedButton(
                  onPressed: _applyDiscount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryRed,
                    padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.06,
                        vertical: screenHeight * 0.02),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.1),
                    ),
                  ),
                  child: Text("Apply",
                      style: TextStyle(
                          color: Colors.white, fontSize: screenWidth * 0.04)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDisplay(Map<String, dynamic> item) {
    final screenWidth = MediaQuery.of(context).size.width;

    final DateTime now = DateTime.now();
    final Timestamp? start = item["Discount_Start_Date"];
    final Timestamp? end = item["Discount_End_Date"];

    bool isDiscountActive = false;
    if (start != null && end != null) {
      final DateTime startDate = start.toDate();
      final DateTime endDate = end.toDate();
      isDiscountActive = now.isAfter(startDate) && now.isBefore(endDate);
    }

    if (isDiscountActive && item["Discount_Price"] != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${item["Price"]} BHD",
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              color: Colors.black54,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          SizedBox(width: screenWidth * 0.02),
          Text(
            "${item["Discount_Price"]} BHD",
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              color: primaryRed,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    } else {
      return Text(
        "${item["Price"]} BHD",
        style: TextStyle(
          fontSize: screenWidth * 0.035,
          color: Colors.black54,
          fontWeight: FontWeight.bold,
        ),
      );
    }
  }
}
