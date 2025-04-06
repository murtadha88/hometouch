import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();

  String _productName = '';
  double _productPrice = 0.0;
  String _productDescription = '';
  double _points = 0.0;

  File? _uploadedImage;
  String? _imageUrl;
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, String>> _fixedCategories = [
    {'id': 'starters', 'name': 'Starters'},
    {'id': 'mains', 'name': 'Main Dishes'},
    {'id': 'chicken_burger', 'name': 'Chicken Burger'},
    {'id': 'meat_burger', 'name': 'Meat Burger'},
    {'id': 'chicken_burger_meal', 'name': 'Chicken Burger Meal'},
    {'id': 'meat_burger_meal', 'name': 'Meat Burger Meal'},
    {'id': 'pizzas', 'name': 'Pizzas'},
    {'id': 'pastas', 'name': 'Pastas'},
    {'id': 'sandwiches', 'name': 'Sandwiches'},
    {'id': 'soups', 'name': 'Soups'},
    {'id': 'desserts', 'name': 'Desserts'},
    {'id': 'drinks', 'name': 'Drinks'},
    {'id': 'salads', 'name': 'Salads'},
    {'id': 'sides', 'name': 'Sides'},
    {'id': 'snacks', 'name': 'Snacks'},
    {'id': 'rice_dishes', 'name': 'Rice Dishes'},
  ];
  String? _selectedCategoryId;

  bool _isButtonEnabled = false;

  final List<TextEditingController> _addOnNameControllers = [];
  final List<TextEditingController> _addOnPriceControllers = [];

  final List<TextEditingController> _removeControllers = [];

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = _fixedCategories[0]['id'];
    _addOnNameControllers.add(TextEditingController());
    _addOnPriceControllers.add(TextEditingController());
    _removeControllers.add(TextEditingController());
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      setState(() {
        _uploadedImage = imageFile;
      });
      await _uploadImage(imageFile);
    }
  }

  Future<void> _uploadImage(File image) async {
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
          _imageUrl = jsonResponse['data']['link'];
        });
      }
    } catch (e) {
      print("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to upload image'),
            backgroundColor: Colors.red),
      );
    }
  }

  void _addAddOnRow(int index) {
    setState(() {
      _addOnNameControllers.add(TextEditingController());
      _addOnPriceControllers.add(TextEditingController());
    });
  }

  void _removeAddOnRow(int index) {
    setState(() {
      _addOnNameControllers.removeAt(index);
      _addOnPriceControllers.removeAt(index);
    });
  }

  void _addRemoveRow(int index) {
    setState(() {
      _removeControllers.add(TextEditingController());
    });
  }

  void _removeRemoveRow(int index) {
    setState(() {
      _removeControllers.removeAt(index);
    });
  }

  void _checkButtonEnabled() {
    if (_productName.isNotEmpty &&
        _productDescription.isNotEmpty &&
        _productPrice > 0) {
      setState(() {
        _isButtonEnabled = true;
      });
    } else {
      setState(() {
        _isButtonEnabled = false;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }
      final selectedCategory = _fixedCategories
          .firstWhere((cat) => cat['id'] == _selectedCategoryId);
      final categoryName = selectedCategory['name']!;

      final vendorRef =
          FirebaseFirestore.instance.collection('vendor').doc(user.uid);
      final categoryDocRef =
          vendorRef.collection('category').doc(_selectedCategoryId);

      final categoryDoc = await categoryDocRef.get();
      if (!categoryDoc.exists) {
        await categoryDocRef.set({'Name': categoryName});
      }

      try {
        final productDocRef = await categoryDocRef.collection('products').add({
          'Name': _productName,
          'Price': _productPrice,
          'Description': _productDescription,
          'Points': _points,
          'Image': _imageUrl ?? '',
        });

        for (int i = 0; i < _addOnNameControllers.length; i++) {
          String addOnName = _addOnNameControllers[i].text.trim();
          double addOnPrice =
              double.tryParse(_addOnPriceControllers[i].text.trim()) ?? 0.0;

          if (addOnName.isNotEmpty) {
            await productDocRef.collection("Add_Ons").add({
              "Name": addOnName,
              "Price": addOnPrice,
            });
          }
        }

        for (int i = 0; i < _removeControllers.length; i++) {
          String removeName = _removeControllers[i].text.trim();
          if (removeName.isNotEmpty) {
            await productDocRef.collection("Remove").add({
              "Name": removeName,
            });
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        print("Error saving product: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving product: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(screenHeight * 0.08),
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
                    top: screenHeight * 0.0025, left: screenWidth * 0.015),
                child: Icon(Icons.arrow_back_ios,
                    color: Colors.white, size: screenHeight * 0.02),
              ),
            ),
          ),
          title: Padding(
            padding: EdgeInsets.only(top: screenHeight * 0.02),
            child: Text(
              'Add Product',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: screenHeight * 0.022,
              ),
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(screenHeight * 0.002),
            child: Divider(
                thickness: screenHeight * 0.001, color: Colors.grey[300]),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildImageCard(screenWidth, screenHeight),
              SizedBox(height: screenHeight * 0.025),
              _buildTextField(
                label: 'Product Name',
                hint: 'Enter product name',
                requiredField: true,
                onChanged: (value) {
                  setState(() {
                    _productName = value;
                  });
                  _checkButtonEnabled();
                },
              ),
              _buildTextField(
                label: 'Product Price in BHD',
                hint: 'Enter product price',
                requiredField: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                ],
                onChanged: (value) {
                  setState(() {
                    _productPrice = double.tryParse(value) ?? 0.0;
                  });
                  _checkButtonEnabled();
                },
              ),
              _buildTextField(
                label: 'Product Description',
                hint: 'Enter product description',
                requiredField: true,
                maxLines: 5,
                onChanged: (value) {
                  setState(() {
                    _productDescription = value;
                  });
                  _checkButtonEnabled();
                },
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: screenWidth * 0.045,
                  bottom: screenHeight * 0.025,
                  right: screenWidth * 0.045,
                ),
                child: DropdownButtonFormField<String>(
                  dropdownColor: Colors.white,
                  value: _selectedCategoryId,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    ),
                  ),
                  items: _fixedCategories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category['id'],
                      child: Text(category['name']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select a category' : null,
                ),
              ),
              _buildTextField(
                label: 'Points',
                hint: 'Enter required points (default 0)',
                requiredField: false,
                keyboardType: TextInputType.number,
                initialValue: '0',
                onChanged: (value) {
                  setState(() {
                    _points = double.tryParse(value) ?? 0.0;
                  });
                },
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: screenWidth * 0.045,
                  bottom: screenHeight * 0.025,
                  right: screenWidth * 0.045,
                ),
                child: Text(
                  'If this product is eligible for the rewards system, please specify the required points to order it for free.',
                  style: TextStyle(
                      color: Colors.grey[600], fontSize: screenWidth * 0.03),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: screenWidth * 0.045),
                child: Text(
                  'Add-Ons:',
                  style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: screenHeight * 0.0125),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _addOnNameControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Container(
                            margin:
                                EdgeInsets.only(bottom: screenHeight * 0.0125),
                            decoration: _textFieldBoxDecoration(),
                            child: TextField(
                              controller: _addOnNameControllers[index],
                              decoration: InputDecoration(
                                hintText: 'Add-On Name',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.025,
                                    vertical: screenHeight * 0.015),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: Container(
                            margin:
                                EdgeInsets.only(bottom: screenHeight * 0.0125),
                            decoration: _textFieldBoxDecoration(),
                            child: TextField(
                              controller: _addOnPriceControllers[index],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*$')),
                              ],
                              decoration: InputDecoration(
                                hintText: 'Price',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.025,
                                    vertical: screenHeight * 0.015),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: (index == _addOnNameControllers.length - 1)
                              ? const Icon(Icons.add, color: Color(0xFFBF0000))
                              : const Icon(Icons.remove_circle,
                                  color: Color(0xFFBF0000)),
                          onPressed: () {
                            if (index == _addOnNameControllers.length - 1) {
                              _addAddOnRow(index);
                            } else {
                              _removeAddOnRow(index);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: screenHeight * 0.025),
              Padding(
                padding: EdgeInsets.only(left: screenWidth * 0.045),
                child: Text(
                  'Remove:',
                  style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: screenHeight * 0.0125),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _removeControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            margin:
                                EdgeInsets.only(bottom: screenHeight * 0.0125),
                            decoration: _textFieldBoxDecoration(),
                            child: TextField(
                              controller: _removeControllers[index],
                              decoration: InputDecoration(
                                hintText: 'Remove Option',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.025,
                                    vertical: screenHeight * 0.015),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: (index == _removeControllers.length - 1)
                              ? const Icon(Icons.add, color: Color(0xFFBF0000))
                              : const Icon(Icons.remove_circle,
                                  color: Color(0xFFBF0000)),
                          onPressed: () {
                            if (index == _removeControllers.length - 1) {
                              _addRemoveRow(index);
                            } else {
                              _removeRemoveRow(index);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isButtonEnabled ? _saveProduct : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBF0000),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    side: const BorderSide(color: Colors.white),
                  ),
                ),
                child: Text(
                  'Add Product',
                  style: TextStyle(
                    color: _isButtonEnabled
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCard(double screenWidth, double screenHeight) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: screenWidth * 0.85,
        height: screenHeight * 0.25,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 4,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (_uploadedImage == null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: screenWidth * 0.17,
                      height: screenWidth * 0.17,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color.fromARGB(255, 184, 211, 216)
                            .withOpacity(0.2),
                      ),
                      child: Icon(
                        Icons.file_copy,
                        size: screenWidth * 0.13,
                        color: Color(0xFFBF0000),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      'Click to upload image',
                      style: TextStyle(
                        color: Color(0xFFBF0000),
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
                child: Image.file(
                  _uploadedImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _pickImage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required bool requiredField,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? initialValue,
    required Function(String) onChanged,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.only(
        left: screenWidth * 0.045,
        bottom: screenHeight * 0.025,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              children: [
                TextSpan(text: label),
                if (requiredField)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: screenWidth * 0.82,
            decoration: _textFieldBoxDecoration(),
            child: TextFormField(
              initialValue: initialValue,
              maxLines: maxLines,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              decoration: InputDecoration(
                hintText: hint,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.025,
                    vertical: screenHeight * 0.015),
              ),
              validator: (value) {
                if (requiredField && (value == null || value.isEmpty)) {
                  return 'Please enter $label';
                }
                return null;
              },
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _textFieldBoxDecoration() {
    final screenWidth = MediaQuery.of(context).size.width;
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(screenWidth * 0.02),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          spreadRadius: 2,
          blurRadius: 4,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}
