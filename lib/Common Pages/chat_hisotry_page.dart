import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hometouch/Common%20Pages/chat_page.dart';
import 'package:timeago/timeago.dart' as timeago;

const Color primaryRed = Color(0xFFBF0000);

class ChatListPage extends StatelessWidget {
  final String currentUserId;

  const ChatListPage({super.key, required this.currentUserId});

  Future<Map<String, String>> getUserDetails(String userId) async {
    final userCollections = ["Customer", "Driver", "vendor"];

    for (String collection in userCollections) {
      final docSnapshot = await FirebaseFirestore.instance
          .collection(collection)
          .doc(userId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        return {
          "name": data["Name"] ?? "Unknown",
          "photo": data["Photo"] ??
              data["Logo"] ??
              "https://i.imgur.com/OtAn7hT.jpeg"
        };
      }
    }

    return {"name": "Unknown", "photo": "https://i.imgur.com/OtAn7hT.jpeg"};
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

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
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryRed,
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
              'Chat History',
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
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("chat")
            .where("participants", arrayContains: currentUserId)
            .orderBy("Last_Message_Time", descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFBF0000)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No chats available.",
                style: TextStyle(fontSize: screenWidth * 0.04),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var chatData =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;

              String chatId = snapshot.data!.docs[index].id;
              String lastMessage =
                  chatData["Last_Message"] ?? "No messages yet";
              Timestamp? lastMessageTime =
                  chatData["Last_Message_Time"] as Timestamp?;
              int unreadCount = (chatData["Unread_Counts"]
                      as Map<String, dynamic>)[currentUserId] ??
                  0;

              bool isUser1 = chatData["User1"] == currentUserId;
              String otherUserId =
                  isUser1 ? chatData["User2"] : chatData["User1"];

              return FutureBuilder<Map<String, String>>(
                future: getUserDetails(otherUserId),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(
                      title: Text(
                        "Loading...",
                        style: TextStyle(fontSize: screenWidth * 0.045),
                      ),
                      trailing: unreadCount > 0
                          ? CircleAvatar(
                              backgroundColor: primaryRed,
                              child: Text(unreadCount.toString()),
                            )
                          : null,
                    );
                  }
                  String otherUserName =
                      userSnapshot.data?["name"] ?? "Unknown";
                  String otherUserImage = userSnapshot.data?["photo"] ??
                      "https://i.imgur.com/OtAn7hT.jpeg";

                  return InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            chatId: chatId,
                            currentUserId: currentUserId,
                          ),
                        ),
                      );

                      FirebaseFirestore.instance
                          .collection("chat")
                          .doc(chatId)
                          .update({
                        "Unread_Counts.$currentUserId": 0,
                      });
                    },
                    child: Card(
                      color: Colors.white,
                      margin: EdgeInsets.only(bottom: screenHeight * 0.015),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(screenWidth * 0.04),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(otherUserImage),
                              radius: screenWidth * 0.08,
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    otherUserName,
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.005),
                                  Text(
                                    lastMessage,
                                    style: TextStyle(
                                        fontSize: screenWidth * 0.04,
                                        color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  lastMessageTime != null
                                      ? timeago.format(lastMessageTime.toDate())
                                      : "No time available",
                                  style: TextStyle(
                                      fontSize: screenWidth * 0.035,
                                      color: Colors.black54),
                                ),
                                SizedBox(height: screenHeight * 0.005),
                                unreadCount > 0
                                    ? CircleAvatar(
                                        radius: screenWidth * 0.04,
                                        backgroundColor: primaryRed,
                                        child: Text(
                                          unreadCount.toString(),
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.035,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    : Icon(Icons.done_all, color: Colors.grey),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
