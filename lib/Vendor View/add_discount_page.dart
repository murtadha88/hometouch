import 'package:flutter/material.dart';

class AddDiscountPage extends StatefulWidget {
  const AddDiscountPage({super.key});

  @override
  State<AddDiscountPage> createState() => _AddDiscountPageState();
}

class _AddDiscountPageState extends State<AddDiscountPage> {
  final List<String> categories = [
    "All",
    "Burger",
    "Sandwich",
    "Pizza",
    "Drinks",
    "Desserts"
  ];
  String selectedCategory = "All";
  final TextEditingController discountController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _categoryKeys = {};

  final Map<String, List<Map<String, dynamic>>> menuItems = {
    "Burger": [
      {
        "name": "Classic Beef Burger",
        "price": 3.0,
        "image": "",
        "selected": false
      },
      {"name": "Rockin' Burgers", "price": 2.8, "image": "", "selected": false},
      {"name": "Burger Ferguson", "price": 3.1, "image": "", "selected": false},
      {
        "name": "Mushroom Burgers",
        "price": 3.5,
        "image": "",
        "selected": false
      },
    ],
    "Sandwich": [
      {"name": "Club Sandwich", "price": 3.5, "image": "", "selected": false},
      {
        "name": "Grilled Cheese Sandwich",
        "price": 3.0,
        "image": "",
        "selected": false
      },
      {
        "name": "Chicken Sandwich",
        "price": 3.2,
        "image": "",
        "selected": false
      },
    ],
    "Pizza": [
      {"name": "Pizza Ferguson", "price": 3.8, "image": "", "selected": false},
      {"name": "Rockin' Pizza", "price": 4.2, "image": "", "selected": false},
      {"name": "Pepperoni Pizza", "price": 4.5, "image": "", "selected": false},
    ],
    "Drinks": [
      {"name": "Cola", "price": 1.0, "image": "", "selected": false},
      {"name": "Lemonade", "price": 1.2, "image": "", "selected": false},
      {"name": "Iced Tea", "price": 1.5, "image": "", "selected": false},
    ],
    "Desserts": [
      {"name": "Chocolate Cake", "price": 2.5, "image": "", "selected": false},
      {"name": "Cheesecake", "price": 3.0, "image": "", "selected": false},
      {"name": "Ice Cream", "price": 2.0, "image": "", "selected": false},
    ],
  };

  @override
  void initState() {
    super.initState();
    for (var category in categories) {
      _categoryKeys[category] = GlobalKey();
    }
  }

  void scrollToCategory(String category) {
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
      selectedCategory = category;
    });
  }

  void applyDiscount() {
    double discount = double.tryParse(discountController.text) ?? 0;
    if (discount <= 0) return;

    setState(() {
      for (var items in menuItems.values) {
        for (var item in items) {
          if (item["selected"]) {
            double originalPrice = item["price"];
            double discountedPrice =
                originalPrice - (originalPrice * discount / 100);
            item["discountedPrice"] = discountedPrice;
            item["selected"] = false;
          }
        }
      }
    });
    discountController.clear();
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
        title: const Text(
          "Add Discount",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return GestureDetector(
                      onTap: () => scrollToCategory(category),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
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
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Scrollbar(
                  controller: _scrollController,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: menuItems.keys.length,
                    itemBuilder: (context, index) {
                      final category = menuItems.keys.elementAt(index);
                      final items = menuItems[category]!;
                      return Column(
                        key: _categoryKeys[category],
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16),
                            child: Text(
                              "$category (${items.length})",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.8,
                            ),
                            itemBuilder: (context, itemIndex) {
                              var item = items[itemIndex];
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    item["selected"] = !item["selected"];
                                  });
                                },
                                child: Card(
                                  color: item["selected"]
                                      ? const Color(0xFFBF0000)
                                      : Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius:
                                                const BorderRadius.vertical(
                                              top: Radius.circular(15),
                                            ),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              color: Colors.grey,
                                              size: 50,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          item["name"],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: item["selected"]
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0, vertical: 4.0),
                                        child: item["discountedPrice"] != null
                                            ? Row(
                                                children: [
                                                  Text(
                                                    "${item["price"]} BHD",
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black,
                                                      decoration: TextDecoration
                                                          .lineThrough,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "${item["discountedPrice"].toStringAsFixed(2)} BHD",
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.red,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Text(
                                                "${item["price"]} BHD",
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black54,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _buildDiscountInput(),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountInput() {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: discountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Enter Discount %",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: applyDiscount,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBF0000),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text("Apply"),
            ),
          ],
        ),
      ),
    );
  }
}
