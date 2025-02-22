import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hometouch/Customer%20View/product_details_page.dart';

class RewardsPage extends StatefulWidget {
  const RewardsPage({Key? key}) : super(key: key);

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  int userPoints = 0;
  List<Map<String, dynamic>> rewardProducts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserPoints();
    _fetchRewardProducts();
  }

  Future<void> _fetchUserPoints() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('Customer')
          .doc(user.uid)
          .get();

      if (userSnapshot.exists) {
        setState(() {
          userPoints = (userSnapshot["Loyalty_Points"] ?? 0).toInt();
        });
      }
    } catch (e) {
      print("❌ Error fetching user points: $e");
    }
  }

  Future<void> _fetchRewardProducts() async {
    try {
      List<Map<String, dynamic>> tempProducts = [];

      QuerySnapshot vendorsSnapshot =
          await FirebaseFirestore.instance.collection('vendor').get();

      for (var vendorDoc in vendorsSnapshot.docs) {
        QuerySnapshot categoriesSnapshot = await FirebaseFirestore.instance
            .collection('vendor')
            .doc(vendorDoc.id)
            .collection('category')
            .get();

        for (var categoryDoc in categoriesSnapshot.docs) {
          QuerySnapshot productsSnapshot = await FirebaseFirestore.instance
              .collection('vendor')
              .doc(vendorDoc.id)
              .collection('category')
              .doc(categoryDoc.id)
              .collection('products')
              .where("Points", isGreaterThan: 0)
              .get();

          for (var productDoc in productsSnapshot.docs) {
            var productData = productDoc.data() as Map<String, dynamic>;

            tempProducts.add({
              "id": productDoc.id,
              "name": productData["Name"] ?? "Unknown Product",
              "image":
                  productData["Image"] ?? "https://via.placeholder.com/150",
              "points": (productData["Points"] ?? 0).toInt(),
              "vendor": vendorDoc["Name"] ?? "Unknown Vendor",
            });
          }
        }
      }

      setState(() {
        rewardProducts = tempProducts;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error fetching reward products: $e");
      setState(() {
        isLoading = false;
      });
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
              'Rewards',
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
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFBF0000)))
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: screenHeight * 0.02),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPointsHeader(screenWidth, screenHeight),
                  const SizedBox(height: 10),
                  _buildProductList(screenWidth),
                ],
              ),
            ),
    );
  }

  Widget _buildPointsHeader(double screenWidth, double screenHeight) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
      decoration: BoxDecoration(
        color: Color(0xFFBF0000),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          "$userPoints Points",
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.06),
        ),
      ),
    );
  }

  Widget _buildProductList(double screenWidth) {
    return Column(
      children: rewardProducts.map((product) {
        return Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            contentPadding: EdgeInsets.all(screenWidth * 0.03),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                product["image"],
                width: screenWidth * 0.15,
                height: screenWidth * 0.15,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              product["name"],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "${product["vendor"]} | ${product["points"]} Points",
              style: TextStyle(
                  color: Color(0xFFBF0000), fontWeight: FontWeight.w500),
            ),
            trailing: Icon(Icons.arrow_forward_ios,
                color: Color(0xFFBF0000), size: screenWidth * 0.05),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailsPage(
                    productId: product["id"],
                    isFromRewards: true,
                    points: product["points"],
                  ),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }
}
