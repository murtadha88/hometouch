import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hometouch/Admin%20View/admin_requests_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRequestDetailsPage extends StatefulWidget {
  final Map<String, dynamic> requestData;
  final Function(Map<String, dynamic>) onAccept;
  final Function(Map<String, dynamic>) onReject;

  const AdminRequestDetailsPage({
    Key? key,
    required this.requestData,
    required this.onAccept,
    required this.onReject,
  }) : super(key: key);

  @override
  _AdminRequestDetailsPageState createState() =>
      _AdminRequestDetailsPageState();
}

class _AdminRequestDetailsPageState extends State<AdminRequestDetailsPage> {
  String? countryName;
  bool isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _getLocationInfo();
  }

  Future<void> _getLocationInfo() async {
    final geoPoint = widget.requestData['Location'] as GeoPoint?;
    if (geoPoint != null) {
      try {
        final places = await placemarkFromCoordinates(
          geoPoint.latitude,
          geoPoint.longitude,
        );

        if (places.isNotEmpty) {
          setState(() {
            countryName = places.first.country;
            isLoadingLocation = false;
          });
        }
      } catch (e) {
        print("Error getting location info: $e");
        setState(() => isLoadingLocation = false);
      }
    } else {
      setState(() => isLoadingLocation = false);
    }
  }

  Future<void> _openGoogleMaps(GeoPoint geoPoint) async {
    final url = 'https://www.google.com/maps/search/?api=1&query='
        '${geoPoint.latitude},${geoPoint.longitude}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }

  void _showAcceptDialog() async {
    final screenWidth = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Center(
            child: Text(
              "Accept Request",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          content: const Text(
            "Are you sure you want to accept this request?",
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
                    minimumSize: Size(screenWidth * 0.25, 40),
                  ),
                  onPressed: () async {
                    await widget.onAccept(widget.requestData);
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AdminRequestsPage()),
                      );
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
                    minimumSize: Size(screenWidth * 0.25, 40),
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

  void _showRejectDialog() async {
    final screenWidth = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Center(
            child: Text(
              "Reject Request",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          content: const Text(
            "Are you sure you want to reject this request?",
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
                    minimumSize: Size(screenWidth * 0.25, 40),
                  ),
                  onPressed: () async {
                    await widget.onReject(widget.requestData);
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AdminRequestsPage()),
                      );
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
                    minimumSize: Size(screenWidth * 0.25, 40),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final role = widget.requestData['Role'] ?? 'N/A';
    final name = widget.requestData['Name'] ?? 'No Name';
    final email = widget.requestData['Email'] ?? 'No Email';
    final phone = widget.requestData['Phone'] ?? 'No Phone';

    final logo = widget.requestData['Logo'] ?? '';
    final category = widget.requestData['Category'] ?? [];
    final vendorType = widget.requestData['Vendor_Type'] ?? '';
    final geoPoint = widget.requestData['Location'] as GeoPoint?;
    final openTime1 = widget.requestData['Open_Time_Period1'] ?? '';
    final closeTime1 = widget.requestData['Close_Time_Period1'] ?? '';
    final twoPeriods = widget.requestData['Two_Periods'] ?? false;
    final openTime2 = widget.requestData['Open_Time_Period2'] ?? '';
    final closeTime2 = widget.requestData['Close_Time_Period2'] ?? '';
    final crImage = widget.requestData['CR_Number'] ?? '';

    final driverLicenseImage = widget.requestData['Driver_License'] ?? '';
    final carOwnershipImage = widget.requestData['Car_Ownership'] ?? '';

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
                  color: const Color(0xFFBF0000),
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
              '$name Details',
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
            child: SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection(
                      "Basic Information",
                      [
                        _buildInfoRow("Email:", email, screenWidth),
                        _buildInfoRow("Phone:", phone, screenWidth),
                      ],
                      screenWidth),
                  if (role == "Vendor") ...[
                    _buildSectionDivider(screenHeight),
                    _buildInfoSection(
                        "Business Details",
                        [
                          _buildInfoRow(
                              "Vendor Type:", vendorType, screenWidth),
                          if (logo.isNotEmpty)
                            _buildImageSection(
                                "Logo", logo, screenWidth, screenHeight),
                          _buildImageSection("CR Document", crImage,
                              screenWidth, screenHeight),
                          _buildLocationSection(
                              geoPoint, screenWidth, screenHeight),
                          if (category.isNotEmpty)
                            Padding(
                              padding:
                                  EdgeInsets.only(top: screenHeight * 0.01),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Categories:",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: screenWidth * 0.04,
                                      )),
                                  Wrap(
                                    spacing: screenWidth * 0.02,
                                    children: category
                                        .map<Widget>((cat) => Chip(
                                              label: Text(cat.toString(),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                        screenWidth * 0.035,
                                                  )),
                                              backgroundColor:
                                                  const Color(0xFFBF0000),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        screenWidth),
                    _buildSectionDivider(screenHeight),
                    _buildInfoSection(
                        "Operating Hours",
                        [
                          _buildInfoRow("Period 1:", "$openTime1 - $closeTime1",
                              screenWidth),
                          if (twoPeriods)
                            _buildInfoRow("Period 2:",
                                "$openTime2 - $closeTime2", screenWidth),
                        ],
                        screenWidth),
                  ],
                  if (role == "Driver") ...[
                    _buildSectionDivider(screenHeight),
                    _buildInfoSection(
                        "Driver Documents",
                        [
                          _buildImageSection("Driver License",
                              driverLicenseImage, screenWidth, screenHeight),
                          _buildImageSection("Car Ownership", carOwnershipImage,
                              screenWidth, screenHeight),
                        ],
                        screenWidth),
                  ],
                ],
              ),
            ),
          ),
          Divider(color: Colors.grey, height: screenHeight * 0.002),
          _buildActionButtons(context, screenWidth, screenHeight),
        ],
      ),
    );
  }

  Widget _buildSectionDivider(double screenHeight) =>
      Divider(color: Colors.grey, height: screenHeight * 0.05);

  Widget _buildInfoSection(
      String title, List<Widget> children, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFBF0000))),
        SizedBox(height: screenWidth * 0.03),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.01),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: screenWidth * 0.3,
            child: Text(label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: screenWidth * 0.035,
                )),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: screenWidth * 0.035),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(
      GeoPoint? geoPoint, double screenWidth, double screenHeight) {
    if (geoPoint == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Location:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.04,
            )),
        SizedBox(height: screenHeight * 0.01),
        isLoadingLocation
            ? CircularProgressIndicator(color: const Color(0xFFBF0000))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (countryName != null)
                    Text(countryName!,
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                        )),
                  SizedBox(height: screenHeight * 0.01),
                  OutlinedButton.icon(
                    icon: Icon(
                      Icons.map,
                      color: const Color(0xFFBF0000),
                      size: screenWidth * 0.05,
                    ),
                    label: Text("View on Map",
                        style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: Color(0xFFBF0000))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFBF0000)),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.015,
                      ),
                    ),
                    onPressed: () => _openGoogleMaps(geoPoint),
                  ),
                ],
              ),
        SizedBox(height: screenHeight * 0.02),
      ],
    );
  }

  Widget _buildImageSection(
      String label, String imageUrl, double screenWidth, double screenHeight) {
    if (imageUrl.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.04,
            )),
        SizedBox(height: screenHeight * 0.01),
        Image.network(
          imageUrl,
          height: screenHeight * 0.25,
          width: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Container(
            height: screenHeight * 0.25,
            color: Colors.grey[200],
            child: Icon(Icons.broken_image,
                size: screenWidth * 0.15, color: Colors.grey),
          ),
        ),
        SizedBox(height: screenHeight * 0.02),
      ],
    );
  }

  Widget _buildActionButtons(
      BuildContext context, double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05, vertical: screenHeight * 0.025),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFBF0000)),
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.012),
              ),
              onPressed: () async => _showRejectDialog(),
              child: Text(
                "Reject",
                style: TextStyle(
                    color: const Color(0xFFBF0000),
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.05),
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.04),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBF0000),
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.012),
              ),
              onPressed: () => _showAcceptDialog(),
              child: Text(
                "Accept",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.05),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
