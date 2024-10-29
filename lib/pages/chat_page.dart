import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/database_service.dart';

class ChatPage extends StatelessWidget {
  final String userId; // Receiver's user ID
  final String username; // Receiver's username

  ChatPage({required this.userId, required this.username});

  final TextEditingController messageController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  final ScrollController _scrollController = ScrollController(); // Add ScrollController

  Future<void> sendMessage() async {
    String message = messageController.text.trim();

    if (message.isNotEmpty) {
      await _databaseService.sendMessage(
        FirebaseAuth.instance.currentUser!.uid, // Current user's ID
        userId, // Receiver's ID
        message,
      );
      messageController.clear(); // Clear the input field after sending

      // Scroll to the bottom after sending a message
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(username),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _databaseService.getMessages(
                FirebaseAuth.instance.currentUser!.uid,
                userId,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                // If there are no messages, show "Start the chat"
                if (snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      "Start the chat",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController, // Use the ScrollController
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    var message = snapshot.data![index];
                    bool isSender = message['senderId'] == FirebaseAuth.instance.currentUser!.uid;

                    return Align(
                      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                        decoration: BoxDecoration(
                          color: isSender ? Colors.blueAccent : Colors.green[200], // Color coding for sender/receiver
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                            bottomLeft: isSender ? Radius.circular(15) : Radius.circular(0),
                            bottomRight: isSender ? Radius.circular(0) : Radius.circular(15),
                          ),
                        ),
                        child: Text(
                          message['message'],
                          style: TextStyle(
                            color: isSender ? Colors.white : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Message input section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[200],
                      hintText: "Type a message",
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blueAccent,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: sendMessage,
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
