import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hometouch/Admin%20View/request_details_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hometouch/Common%20Pages/role_page.dart';

class AdminRequestsPage extends StatefulWidget {
  const AdminRequestsPage({Key? key}) : super(key: key);

  @override
  State<AdminRequestsPage> createState() => _AdminRequestsPageState();
}

class _AdminRequestsPageState extends State<AdminRequestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;

  List<Map<String, dynamic>> driverRequests = [];
  List<Map<String, dynamic>> vendorRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('request')
          .where('Accepted', isNull: true)
          .get();

      List<Map<String, dynamic>> tempDriver = [];
      List<Map<String, dynamic>> tempVendor = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['docId'] = doc.id;
        final role = data['Role'] ?? '';

        if (role == 'Driver') {
          tempDriver.add(data);
        } else if (role == 'Vendor') {
          tempVendor.add(data);
        }
      }

      setState(() {
        driverRequests = tempDriver;
        vendorRequests = tempVendor;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching requests: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _acceptRequest(Map<String, dynamic> requestData) async {
    try {
      final docId = requestData['docId'];
      await FirebaseFirestore.instance
          .collection('request')
          .doc(docId)
          .update({"Accepted": true});

      if (requestData['Role'] == 'Driver') {
        await FirebaseFirestore.instance.collection('Driver').doc(docId).set({
          "Name": requestData['Name'],
          "Email": requestData['Email'],
          "Phone": requestData['Phone'],
          "Location": requestData['Location'],
          "Driver_License": requestData['Driver_License'],
          "Car_Ownership": requestData['Car_Ownership'],
        });
      } else if (requestData['Role'] == 'Vendor') {
        await FirebaseFirestore.instance.collection('vendor').doc(docId).set({
          "Name": requestData['Name'],
          "Email": requestData['Email'],
          "Phone": requestData['Phone'],
          "Logo": requestData['Logo'],
          "Category": requestData['Category'],
          "Vendor_Type": requestData['Vendor_Type'],
          "Location": requestData['Location'],
          "Open_Time_Period1": requestData['Open_Time_Period1'],
          "Close_Time_Period1": requestData['Close_Time_Period1'],
          "Two_Periods": requestData['Two_Periods'],
          "Open_Time_Period2": requestData['Open_Time_Period2'],
          "Close_Time_Period2": requestData['Close_Time_Period2'],
          "CR_Number": requestData['CR_Number'],
        });
      }

      setState(() {
        if (requestData['Role'] == 'Driver') {
          driverRequests.removeWhere((item) => item['docId'] == docId);
        } else {
          vendorRequests.removeWhere((item) => item['docId'] == docId);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request Accepted!")),
      );
    } catch (e) {
      print('Error accepting request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error accepting request: $e")),
      );
    }
  }

  Future<void> _rejectRequest(Map<String, dynamic> requestData) async {
    try {
      final docId = requestData['docId'];
      await FirebaseFirestore.instance
          .collection('request')
          .doc(docId)
          .update({"Accepted": false});

      setState(() {
        if (requestData['Role'] == 'Driver') {
          driverRequests.removeWhere((item) => item['docId'] == docId);
        } else {
          vendorRequests.removeWhere((item) => item['docId'] == docId);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request Rejected!")),
      );
    } catch (e) {
      print('Error rejecting request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error rejecting request: $e")),
      );
    }
  }

  void _showAcceptDialog(Map<String, dynamic> requestData) {
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
                    Navigator.of(context).pop();
                    await _acceptRequest(requestData);
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

  void _showRejectDialog(Map<String, dynamic> requestData) {
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
                    Navigator.of(context).pop();
                    await _rejectRequest(requestData);
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

  void showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
          title: const Text(
            'Sign Out?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFBF0000),
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Are you sure you want to sign out?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFBF0000)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        await prefs.setBool('isLoggedIn', false);

                        if (mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const RoleSelectionPage()),
                            (route) => false,
                          );
                        }
                      },
                      child: const Text(
                        'Yes',
                        style: TextStyle(
                          color: Color(0xFFBF0000),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBF0000),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'No',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Requests',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Color(0xFFBF0000)),
              onPressed: () => showSignOutDialog(context),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFBF0000),
          unselectedLabelColor: Colors.black54,
          indicatorColor: const Color(0xFFBF0000),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: "Drivers"),
            Tab(text: "Vendors"),
          ],
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFBF0000)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRequestsList(driverRequests, screenWidth, screenHeight),
                _buildRequestsList(vendorRequests, screenWidth, screenHeight),
              ],
            ),
    );
  }

  Widget _buildRequestsList(List<Map<String, dynamic>> requests,
      double screenWidth, double screenHeight) {
    if (requests.isEmpty) {
      return const Center(child: Text("No requests found."));
    }

    return ListView.builder(
      padding: EdgeInsets.all(screenWidth * 0.04),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final requestData = requests[index];
        final name = requestData['Name'] ?? 'No Name';
        final email = requestData['Email'] ?? 'No Email';
        final phone = requestData['Phone'] ?? 'No Email';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminRequestDetailsPage(
                  requestData: requestData,
                  onAccept: _acceptRequest,
                  onReject: _rejectRequest,
                ),
              ),
            );
          },
          child: Card(
            elevation: 3,
            margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: const Color(0xFFBF0000),
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    "Email: $email",
                    style: TextStyle(
                      fontSize: screenWidth * 0.037,
                    ),
                  ),
                  Text(
                    "Phone: $phone",
                    style: TextStyle(fontSize: screenWidth * 0.04),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                        onPressed: () => _showRejectDialog(requestData),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFBF0000)),
                          minimumSize: Size(screenWidth * 0.4, 40),
                        ),
                        child: const Text(
                          "Reject",
                          style: TextStyle(
                              color: Color(0xFFBF0000),
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _showAcceptDialog(requestData),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBF0000),
                          minimumSize: Size(screenWidth * 0.4, 40),
                        ),
                        child: const Text(
                          "Accept",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
