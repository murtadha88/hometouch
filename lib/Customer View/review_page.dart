import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class ReviewPage extends StatefulWidget {
  final String? vendorId;
  final String? productId;
  final String? categoryId;

  const ReviewPage({Key? key, this.vendorId, this.productId, this.categoryId})
      : super(key: key);

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final TextEditingController _reviewController = TextEditingController();
  final FocusNode _reviewFocusNode = FocusNode();
  int _rating = 5;
  String _ratingLabel = "Excellent";
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;

  void _updateRatingLabel(int rating) {
    switch (rating) {
      case 5:
        _ratingLabel = "Excellent";
        break;
      case 4:
        _ratingLabel = "Good";
        break;
      case 3:
        _ratingLabel = "Average";
        break;
      case 2:
        _ratingLabel = "Poor";
        break;
      case 1:
        _ratingLabel = "Terrible";
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    fetchReviews().then((reviews) {
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _reviewFocusNode.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> fetchReviews() async {
    try {
      QuerySnapshot reviewSnapshot = await FirebaseFirestore.instance
          .collection('review')
          .where(widget.vendorId != null ? "Vendor_ID" : "Product_ID",
              isEqualTo: widget.vendorId ?? widget.productId)
          .orderBy("Date", descending: true)
          .get();

      List<Map<String, dynamic>> reviews = [];

      for (var doc in reviewSnapshot.docs) {
        Map<String, dynamic> reviewData = doc.data() as Map<String, dynamic>;

        DocumentReference customerRef = reviewData['Customer_ID'];
        DocumentSnapshot customerSnapshot = await customerRef.get();

        Map<String, dynamic>? customerData =
            customerSnapshot.data() as Map<String, dynamic>?;

        String formattedDate = reviewData["Date"] != null
            ? DateFormat('dd MMM yyyy').format(reviewData["Date"].toDate())
            : "Unknown Date";

        reviews.add({
          "customerName": customerData?["Name"] ?? "Unknown Customer",
          "customerPhoto": customerData?["Photo"],
          "rating": reviewData["Rating"] ?? 0,
          "review": reviewData["Review"] ?? "No review",
          "date": formattedDate,
        });
      }

      return reviews;
    } catch (e) {
      print("❌ Error fetching reviews: $e");
      return [];
    }
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Review cannot be empty")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("You need to be logged in to submit a review")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('review').add({
        "Customer_ID":
            FirebaseFirestore.instance.collection('Customer').doc(user.uid),
        "Vendor_ID": widget.vendorId,
        "Product_ID": widget.productId,
        "Review": _reviewController.text.trim(),
        "Rating": _rating,
        "Date": FieldValue.serverTimestamp(),
      });

      _reviewController.clear();
      setState(() {
        _rating = 5;
        _ratingLabel = "Excellent";
      });

      _reviewFocusNode.unfocus();

      List<Map<String, dynamic>> updatedReviews = await fetchReviews();
      setState(() {
        _reviews = updatedReviews;
      });

      await _updateAverageRating();
    } catch (e) {
      print("Error submitting review: $e");
    }
  }

  Future<void> _updateAverageRating() async {
    if (widget.vendorId == null && widget.productId == null) {
      print("ERROR: No Vendor or Product ID provided.");
      return;
    }

    try {
      String field = widget.vendorId != null ? "Vendor_ID" : "Product_ID";
      String targetId = widget.vendorId ?? widget.productId!;

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection("review")
          .where(field, isEqualTo: targetId)
          .get();

      if (snapshot.docs.isEmpty) {
        print("No reviews found for $field: $targetId");
        return;
      }

      double totalRating = 0.0;
      for (var doc in snapshot.docs) {
        totalRating += (doc["Rating"] as num).toDouble();
      }
      double averageRating = totalRating / snapshot.docs.length;

      averageRating = double.parse(averageRating.toStringAsFixed(1));

      DocumentReference targetRef;

      if (widget.vendorId != null) {
        targetRef = FirebaseFirestore.instance
            .collection("vendor")
            .doc(widget.vendorId);
      } else {
        if (widget.categoryId == null) {
          print("ERROR: categoryId is required for updating product rating.");
          return;
        }

        QuerySnapshot vendorSnapshot =
            await FirebaseFirestore.instance.collection("vendor").get();

        String? vendorId;
        for (var vendorDoc in vendorSnapshot.docs) {
          DocumentSnapshot productDoc = await FirebaseFirestore.instance
              .collection("vendor")
              .doc(vendorDoc.id)
              .collection("category")
              .doc(widget.categoryId)
              .collection("products")
              .doc(widget.productId)
              .get();

          if (productDoc.exists) {
            vendorId = vendorDoc.id;
            break;
          }
        }

        if (vendorId == null) {
          print("ERROR: Vendor ID not found for product: ${widget.productId}");
          return;
        }

        targetRef = FirebaseFirestore.instance
            .collection("vendor")
            .doc(vendorId)
            .collection("category")
            .doc(widget.categoryId)
            .collection("products")
            .doc(widget.productId);
      }

      await targetRef.update({"Rating": averageRating});
    } catch (e) {
      print("❌ Error updating average rating: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

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
              'Reviews',
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
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFBF0000)))
                : _reviews.isEmpty
                    ? Center(
                        child: Text("No reviews yet.",
                            style: TextStyle(fontSize: screenHeight * 0.02)))
                    : ListView.separated(
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        itemCount: _reviews.length,
                        separatorBuilder: (context, index) => Divider(
                          color: Colors.black26,
                          thickness: screenHeight * 0.001,
                          height: screenHeight * 0.03,
                        ),
                        itemBuilder: (context, index) {
                          final review = _reviews[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                leading: CircleAvatar(
                                  radius: screenWidth * 0.07,
                                  backgroundImage: (review["customerPhoto"] !=
                                              null &&
                                          review["customerPhoto"]!.isNotEmpty)
                                      ? MemoryImage(base64Decode(
                                          review["customerPhoto"]!))
                                      : NetworkImage(
                                          'https://i.imgur.com/OtAn7hT.jpeg',
                                        ),
                                ),
                                title: Text(
                                  review["customerName"],
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: screenHeight * 0.022),
                                ),
                                subtitle: Text(
                                  review["date"],
                                  style: TextStyle(
                                      fontSize: screenHeight * 0.018,
                                      color: Colors.black54),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                    5,
                                    (index) => Icon(
                                      index < (review["rating"] ?? 0)
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Color(0xFFBF0000),
                                      size: screenWidth * 0.06,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.04),
                                child: Text(review["review"],
                                    style: TextStyle(
                                        fontSize: screenHeight * 0.02)),
                              ),
                            ],
                          );
                        },
                      ),
          ),
          Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                  top: BorderSide(
                      color: Colors.black26, width: screenHeight * 0.001)),
            ),
            child: Column(
              children: [
                Text(
                  "Add Rate and Review",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: screenHeight * 0.022),
                ),
                SizedBox(height: screenHeight * 0.015),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () {
                        setState(() {
                          _rating = index + 1;
                          _updateRatingLabel(_rating);
                        });
                      },
                      icon: Icon(Icons.star,
                          color:
                              index < _rating ? Color(0xFFBF0000) : Colors.grey,
                          size: screenWidth * 0.07),
                    );
                  }),
                ),
                Text(
                  _ratingLabel,
                  style: TextStyle(
                      fontSize: screenHeight * 0.02,
                      fontWeight: FontWeight.bold),
                ),
                TextField(
                  controller: _reviewController,
                  focusNode: _reviewFocusNode,
                  decoration: InputDecoration(
                    hintText: "Write your review...",
                    suffixIcon: IconButton(
                      onPressed: _submitReview,
                      icon: Icon(Icons.send,
                          color: Color(0xFFBF0000), size: screenHeight * 0.035),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
