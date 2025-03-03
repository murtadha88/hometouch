import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  NotificationPage({super.key});

  String formatDate(String dateString) {
    DateTime date = DateTime.parse(dateString);
    DateTime today = DateTime.now();
    DateTime yesterday = today.subtract(Duration(days: 1));

    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return 'Today';
    }

    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    }

    return DateFormat('dd MMM yyyy').format(date);
  }

  Future<List<Map<String, dynamic>>> _getUserNotifications(
      String userId) async {
    try {
      var notificationsSnapshot = await _firestore
          .collection('Customer')
          .doc(userId)
          .collection('notification')
          .get();

      if (notificationsSnapshot.docs.isEmpty) {
        return [];
      }

      List<Map<String, dynamic>> notifications = notificationsSnapshot.docs
          .map((doc) => {
                'title': doc['Title'],
                'subtitle': doc['Message'],
                'type': doc['Type'],
                'date': formatDate(doc['Date'].toDate().toString()),
              })
          .toList();

      print('Notification: $notifications');

      return notifications;
    } catch (e) {
      print("Error fetching notifications: $e");
      return [];
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
              'Notification',
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getUserNotifications(_auth.currentUser?.uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading notifications'));
          }

          if (snapshot.data?.isEmpty ?? true) {
            return _buildNoNotificationsView(
                context, screenWidth, screenHeight);
          }

          return ListView(
            children: _buildNotificationList(
                snapshot.data!, screenWidth, screenHeight),
          );
        },
      ),
    );
  }

  Widget _buildNoNotificationsView(
      BuildContext context, double screenWidth, double screenHeight) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
            'https://i.imgur.com/V8iPAob.png',
            height: screenHeight * 0.4,
            width: screenWidth * 0.75,
          ),
          SizedBox(height: screenHeight * 0.03),
          Text(
            'No Notification Yet',
            style: TextStyle(
                fontSize: screenHeight * 0.03,
                fontWeight: FontWeight.w900,
                color: Colors.black),
          ),
          SizedBox(height: screenHeight * 0.02),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
            child: Text(
              'You have no notification right now! Come back later.',
              style: TextStyle(
                  fontSize: screenHeight * 0.02,
                  fontWeight: FontWeight.normal,
                  color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFBF0000),
              padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.2, vertical: screenHeight * 0.02),
            ),
            child: Text(
              'Go Back',
              style:
                  TextStyle(color: Colors.white, fontSize: screenHeight * 0.02),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNotificationList(List<Map<String, dynamic>> notifications,
      double screenWidth, double screenHeight) {
    Map<String, List<Map<String, dynamic>>> groupedNotifications = {};

    for (var notification in notifications) {
      String date = notification['date'];
      if (groupedNotifications.containsKey(date)) {
        groupedNotifications[date]!.add(notification);
      } else {
        groupedNotifications[date] = [notification];
      }
    }

    var sortedDates = groupedNotifications.keys.toList()
      ..sort((a, b) {
        if (a == 'Today') return -1;
        if (b == 'Today') return 1;
        return b.compareTo(a);
      });

    List<Widget> notificationWidgets = [];

    for (var date in sortedDates) {
      notificationWidgets.add(_buildDivider());
      notificationWidgets.add(_buildDateSeparator(
          date: date, screenWidth: screenWidth, screenHeight: screenHeight));
      notificationWidgets.add(_buildDivider());

      var notificationList = groupedNotifications[date]!;
      for (int i = 0; i < notificationList.length; i++) {
        notificationWidgets.add(_buildNotificationTile(
            notificationList[i], screenWidth, screenHeight));
      }
    }

    return notificationWidgets;
  }

  Widget _buildDateSeparator(
      {required String date,
      required double screenWidth,
      required double screenHeight}) {
    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: screenHeight * 0.02, horizontal: screenWidth * 0.05),
      child: Text(
        date,
        style: TextStyle(
            fontSize: screenHeight * 0.02,
            fontWeight: FontWeight.bold,
            color: Colors.black54),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(top: 0.0, bottom: 10),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> notification,
      double screenWidth, double screenHeight) {
    IconData icon;
    Color iconColor = Colors.blue;

    switch (notification['type']) {
      case 'order':
        icon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'delivery':
        icon = Icons.local_shipping;
        iconColor = Colors.orange;
        break;
      case 'discount':
        icon = Icons.local_offer;
        iconColor = Colors.red;
        break;
      case 'canceled':
        icon = Icons.cancel;
        iconColor = Colors.redAccent;
        break;
      case 'payment':
        icon = Icons.payment;
        iconColor = Colors.green;
        break;
      case 'new_items':
        icon = Icons.new_releases;
        iconColor = Colors.purple;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.2),
          child: Icon(
            icon,
            color: iconColor,
          ),
        ),
        title: Text(
          notification['title'],
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(notification['subtitle']),
      ),
    );
  }
}
