import 'package:flutter/material.dart';

class AddProductReviewPage extends StatefulWidget {
  final String productName;

  const AddProductReviewPage({super.key, required this.productName});

  @override
  State<AddProductReviewPage> createState() => _AddProductReviewPageState();
}

class _AddProductReviewPageState extends State<AddProductReviewPage> {
  final TextEditingController _reviewController = TextEditingController();
  int _rating = 5;
  String _ratingLabel = "Excellent";

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

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

  void _submitReview() {
    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Review cannot be empty")),
      );
      return;
    }

    Navigator.pop(context, {
      "rating": _rating,
      "comment": _reviewController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const CircleAvatar(
            backgroundColor: Color(0xFFBF0000),
            child: Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Rate ${widget.productName}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.0),
                      image: const DecorationImage(
                        image: NetworkImage(
                          "https://via.placeholder.com/400x200.png?text=Product+Image",
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                  const Text(
                    "Please rate and review the product",
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Please Rate the Service",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _ratingLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                        icon: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black26),
                      borderRadius: BorderRadius.circular(8.0),
                      color: Colors.grey[100],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _reviewController,
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            decoration: const InputDecoration(
                              hintText: "Write your review",
                              contentPadding: EdgeInsets.all(12.0),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _submitReview,
                          icon: const Icon(
                            Icons.send,
                            color: Color(0xFFBF0000),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
