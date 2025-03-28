import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class EditProductPage extends StatefulWidget {
  final String vendorId;
  final String categoryId;
  final String productId;

  const EditProductPage({
    Key? key,
    required this.vendorId,
    required this.categoryId,
    required this.productId,
  }) : super(key: key);

  @override
  _EditProductPageState createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();

  File? _uploadedImage;
  String? _imageUrl;
  final ImagePicker _picker = ImagePicker();

  bool _isButtonEnabled = false;

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _pointsController;

  List<TextEditingController> _addOnNameControllers = [];
  List<TextEditingController> _addOnPriceControllers = [];

  List<TextEditingController> _removeControllers = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _priceController = TextEditingController();
    _descriptionController = TextEditingController();
    _pointsController = TextEditingController();
    _fetchProductData();
  }

  Future<void> _fetchProductData() async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('vendor')
          .doc(widget.vendorId)
          .collection('category')
          .doc(widget.categoryId)
          .collection('products')
          .doc(widget.productId);

      final docSnap = await docRef.get();
      if (docSnap.exists) {
        final data = docSnap.data()!;
        setState(() {
          _nameController.text = data['Name'] ?? '';
          _priceController.text =
              (data['Price'] as num?)?.toStringAsFixed(3) ?? '0.0';
          _descriptionController.text = data['Description'] ?? '';
          _pointsController.text = (data['Points'] as num?)?.toString() ?? '0';
          _imageUrl = data['Image'] ?? '';
        });
        await _loadAddOns(docRef);
        await _loadRemove(docRef);

        _checkButtonEnabled();
      }
    } catch (e) {
      print("Error fetching product data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching product data: $e')),
      );
    }
  }

  Future<void> _loadAddOns(DocumentReference productDocRef) async {
    try {
      final addOnsSnap = await productDocRef.collection('Add_Ons').get();
      _addOnNameControllers.clear();
      _addOnPriceControllers.clear();

      for (var doc in addOnsSnap.docs) {
        final addOnData = doc.data();
        String name = addOnData['Name'] ?? '';
        double price = (addOnData['Price'] as num?)?.toDouble() ?? 0.0;

        _addOnNameControllers.add(TextEditingController(text: name));
        _addOnPriceControllers
            .add(TextEditingController(text: price.toString()));
      }

      if (addOnsSnap.docs.isEmpty) {
        _addOnNameControllers.add(TextEditingController());
        _addOnPriceControllers.add(TextEditingController());
      }
      setState(() {});
    } catch (e) {
      print("Error loading Add_Ons: $e");
    }
  }

  Future<void> _loadRemove(DocumentReference productDocRef) async {
    try {
      final removeSnap = await productDocRef.collection('Remove').get();
      _removeControllers.clear();

      for (var doc in removeSnap.docs) {
        final removeData = doc.data();
        String name = removeData['Name'] ?? '';
        _removeControllers.add(TextEditingController(text: name));
      }

      if (removeSnap.docs.isEmpty) {
        _removeControllers.add(TextEditingController());
      }
      setState(() {});
    } catch (e) {
      print("Error loading Remove: $e");
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
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
          backgroundColor: Colors.red,
        ),
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
    final nameValid = _nameController.text.isNotEmpty;
    final priceValid = double.tryParse(_priceController.text) != null;
    final descValid = _descriptionController.text.isNotEmpty;

    setState(() {
      _isButtonEnabled = nameValid && priceValid && descValid;
    });
  }

  Future<void> _updateProduct() async {
    if (_formKey.currentState!.validate()) {
      try {
        final productDocRef = FirebaseFirestore.instance
            .collection('vendor')
            .doc(widget.vendorId)
            .collection('category')
            .doc(widget.categoryId)
            .collection('products')
            .doc(widget.productId);

        final updatedProduct = {
          'Name': _nameController.text,
          'Price': double.parse(_priceController.text),
          'Description': _descriptionController.text,
          'Points': double.tryParse(_pointsController.text) ?? 0.0,
          'Image': _imageUrl ?? '',
        };

        await productDocRef.update(updatedProduct);

        final addOnsSnap = await productDocRef.collection('Add_Ons').get();
        for (var doc in addOnsSnap.docs) {
          await doc.reference.delete();
        }

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

        final removeSnap = await productDocRef.collection('Remove').get();
        for (var doc in removeSnap.docs) {
          await doc.reference.delete();
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
          const SnackBar(content: Text('Product updated successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        print("Error updating product: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating product: $e')),
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
              top: screenHeight * 0.025,
              left: screenWidth * 0.02,
            ),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFBF0000),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.only(top: 2, left: 6),
                child: Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: screenHeight * 0.02,
                ),
              ),
            ),
          ),
          title: Padding(
            padding: EdgeInsets.only(top: screenHeight * 0.02),
            child: Text(
              'Edit Product',
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
              thickness: screenHeight * 0.001,
              color: Colors.grey[300],
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: _buildBody(screenWidth, screenHeight),
    );
  }

  Widget _buildBody(double screenWidth, double screenHeight) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildImageCard(screenWidth, screenHeight),
              SizedBox(height: screenHeight * 0.025),
              _buildTextField(
                label: 'Product Name',
                hint: 'Enter product name',
                requiredField: true,
                controller: _nameController,
                onChanged: (value) => _checkButtonEnabled(),
              ),
              _buildTextField(
                label: 'Product Price in BHD',
                hint: 'Enter product price',
                requiredField: true,
                controller: _priceController,
                onChanged: (value) => _checkButtonEnabled(),
              ),
              _buildTextField(
                label: 'Product Description',
                hint: 'Enter product description',
                requiredField: true,
                controller: _descriptionController,
                onChanged: (value) => _checkButtonEnabled(),
              ),
              _buildTextField(
                label: 'Points',
                hint: 'Enter required points (default 0)',
                requiredField: false,
                controller: _pointsController,
                onChanged: (value) {},
              ),
              Padding(
                padding: const EdgeInsets.only(left: 18, bottom: 20, right: 18),
                child: Text(
                  'If this product is eligible for the rewards system, please specify the required points to order it for free.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),
              _buildAddOnsSection(screenWidth),
              _buildRemoveSection(screenWidth),
              ElevatedButton(
                onPressed: _isButtonEnabled ? _updateProduct : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBF0000),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.white),
                  ),
                ),
                child: Text(
                  'Save Changes',
                  style: TextStyle(
                    color: _isButtonEnabled
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
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
          borderRadius: BorderRadius.circular(8),
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
            if (_uploadedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _uploadedImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              )
            else if (_imageUrl != null && _imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, _, __) {
                    return Center(
                      child: Text(
                        'Image not available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  },
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color.fromARGB(255, 184, 211, 216)
                            .withOpacity(0.2),
                      ),
                      child: const Icon(
                        Icons.file_copy,
                        size: 50,
                        color: Color(0xFFBF0000),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Click to upload image',
                      style: TextStyle(
                        color: Color(0xFFBF0000),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    required Function(String) onChanged,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.only(left: 18, bottom: 20, right: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 16,
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
              controller: controller,
              maxLines: maxLines,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              decoration: InputDecoration(
                hintText: hint,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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

  Widget _buildAddOnsSection(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 18),
            child: Text(
              'Add-Ons:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _addOnNameControllers.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: _textFieldBoxDecoration(),
                      child: TextField(
                        controller: _addOnNameControllers[index],
                        decoration: const InputDecoration(
                          hintText: 'Add-On Name',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: _textFieldBoxDecoration(),
                      child: TextField(
                        controller: _addOnPriceControllers[index],
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*$')),
                        ],
                        decoration: const InputDecoration(
                          hintText: 'Price',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 12),
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
      ],
    );
  }

  Widget _buildRemoveSection(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 18),
            child: Text(
              'Remove:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _removeControllers.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: _textFieldBoxDecoration(),
                      child: TextField(
                        controller: _removeControllers[index],
                        decoration: const InputDecoration(
                          hintText: 'Remove Option',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 12),
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
      ],
    );
  }

  BoxDecoration _textFieldBoxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
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
