import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

const Color primaryRed = Color(0xFFBF0000);

class ChatPage extends StatefulWidget {
  final String chatId;
  final String currentUserId;

  const ChatPage(
      {super.key, required this.chatId, required this.currentUserId});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _messageController = TextEditingController();

  String receiverName = "Chat";
  String receiverPhoto = "";
  String receiverPhone = "";
  String senderPhoto = "";

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _fetchChatParticipants();
    _markMessagesAsSeenAndResetUnread();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _markMessagesAsSeenAndResetUnread() async {
    final chatRef =
        FirebaseFirestore.instance.collection("chat").doc(widget.chatId);
    final messageRef = chatRef.collection("message");

    final batch = FirebaseFirestore.instance.batch();

    batch.update(chatRef, {
      "Unread_Counts.${widget.currentUserId}": 0,
    });

    final unseenMessages = await messageRef
        .where("Sender_ID", isNotEqualTo: widget.currentUserId)
        .where("Seen", isEqualTo: false)
        .get();

    for (var doc in unseenMessages.docs) {
      batch.update(doc.reference, {"Seen": true});
    }

    await batch.commit();
  }

  Future<void> _fetchChatParticipants() async {
    try {
      DocumentSnapshot chatSnapshot = await FirebaseFirestore.instance
          .collection("chat")
          .doc(widget.chatId)
          .get();

      if (!chatSnapshot.exists) return;

      Map<String, dynamic> chatData =
          chatSnapshot.data() as Map<String, dynamic>;

      String receiverId = chatData["User1"] == widget.currentUserId
          ? chatData["User2"]
          : chatData["User1"];

      await _fetchUserDetails(receiverId, isReceiver: true);
      await _fetchUserDetails(widget.currentUserId, isReceiver: false);
    } catch (e) {
      print("Error fetching chat participants: $e");
    }
  }

  Future<void> _fetchUserDetails(String userId,
      {required bool isReceiver}) async {
    final collections = ["Customer", "Driver", "vendor"];

    for (String collection in collections) {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection(collection)
          .doc(userId)
          .get();

      if (userSnapshot.exists) {
        Map<String, dynamic> userData =
            userSnapshot.data() as Map<String, dynamic>;

        setState(() {
          if (isReceiver) {
            receiverName = userData["Name"] ?? "Unknown";
            receiverPhoto = userData["Photo"] ??
                userData["Logo"] ??
                "https://i.imgur.com/OtAn7hT.jpeg";
            receiverPhone = userData["Phone"] ?? "";
          } else {
            senderPhoto = userData["Photo"] ??
                userData["Logo"] ??
                "https://i.imgur.com/OtAn7hT.jpeg";
          }
        });
        break;
      }
    }
  }

  Future<void> _makePhoneCall() async {
    final Uri callUri = Uri(scheme: 'tel', path: receiverPhone);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unable to make call"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _sendMessage() async {
    String message = _messageController.text.trim();
    if (message.isEmpty) return;

    try {
      DocumentSnapshot chatSnapshot = await FirebaseFirestore.instance
          .collection("chat")
          .doc(widget.chatId)
          .get();

      if (!chatSnapshot.exists) return;

      Map<String, dynamic> chatData =
          chatSnapshot.data() as Map<String, dynamic>;

      Map<String, dynamic> unreadCounts =
          (chatData["Unread_Counts"] as Map<String, dynamic>?) ?? {};

      String receiverId = chatData["User1"] == widget.currentUserId
          ? chatData["User2"]
          : chatData["User1"];

      if (!unreadCounts.containsKey(receiverId)) {
        unreadCounts[receiverId] = 0;
      }

      await FirebaseFirestore.instance
          .collection("chat")
          .doc(widget.chatId)
          .collection("message")
          .add({
        "Sender_ID": widget.currentUserId,
        "Text": message,
        "Time": FieldValue.serverTimestamp(),
        "Seen": false,
      });

      await FirebaseFirestore.instance
          .collection("chat")
          .doc(widget.chatId)
          .update({
        "Last_Message": message,
        "Last_Message_Time": FieldValue.serverTimestamp(),
        "Unread_Counts.$receiverId": FieldValue.increment(1),
        "Seen": false,
      });

      _messageController.clear();
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(screenHeight * 0.09),
        child: AppBar(
          backgroundColor: Colors.white,
          leading: Padding(
            padding: EdgeInsets.only(
                top: screenHeight * 0.025, left: screenWidth * 0.02),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: CircleAvatar(
                backgroundColor: primaryRed,
                radius: screenWidth * 0.05,
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: screenHeight * 0.025,
                ),
              ),
            ),
          ),
          title: Padding(
            padding: EdgeInsets.only(top: screenHeight * 0.02),
            child: Text(
              receiverName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: screenHeight * 0.027,
              ),
            ),
          ),
          centerTitle: true,
          actions: [
            if (receiverPhone.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                    top: screenHeight * 0.025, right: screenWidth * 0.04),
                child: GestureDetector(
                  onTap: _makePhoneCall,
                  child: CircleAvatar(
                    backgroundColor: primaryRed,
                    radius: screenWidth * 0.05,
                    child: Icon(
                      Icons.call,
                      color: Colors.white,
                      size: screenWidth * 0.05,
                    ),
                  ),
                ),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(screenHeight * 0.002),
            child: Divider(
                thickness: screenHeight * 0.001, color: Colors.grey[300]),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("chat")
                  .doc(widget.chatId)
                  .collection("message")
                  .orderBy("Time", descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No messages yet",
                      style: TextStyle(fontSize: screenWidth * 0.04),
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController
                        .jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message =
                        messages[index].data() as Map<String, dynamic>;
                    bool isMe = message["Sender_ID"] == widget.currentUserId;

                    return Row(
                      mainAxisAlignment: isMe
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        if (!isMe)
                          CircleAvatar(
                            backgroundImage: NetworkImage(receiverPhoto),
                            radius: screenWidth * 0.04,
                          ),
                        SizedBox(width: screenWidth * 0.03),
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: screenWidth * 0.65,
                          ),
                          margin: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.007),
                          padding: EdgeInsets.all(screenWidth * 0.03),
                          decoration: BoxDecoration(
                            color: isMe ? primaryRed : const Color(0xFFF6CED9),
                            borderRadius:
                                BorderRadius.circular(screenWidth * 0.04),
                          ),
                          child: Text(
                            message["Text"],
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              color: isMe ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        if (isMe)
                          CircleAvatar(
                            backgroundImage: NetworkImage(senderPhoto),
                            radius: screenWidth * 0.04,
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(screenWidth * 0.02,
                screenHeight * 0.01, screenWidth * 0.02, screenHeight * 0.015),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    focusNode: _focusNode,
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.05),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                Container(
                  height: screenWidth * 0.12,
                  width: screenWidth * 0.12,
                  decoration: const BoxDecoration(
                    color: primaryRed,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: Icon(Icons.send,
                        color: Colors.white, size: screenWidth * 0.06),
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
