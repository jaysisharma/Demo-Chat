import 'package:flutter/material.dart';
import 'chat_page.dart';

class InboxPage extends StatelessWidget {
  final List<Map<String, dynamic>> users; // List of users to chat with

  InboxPage({required this.users});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inbox'),
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: users.isEmpty
          ? Center(child: Text('No users in your inbox.'))
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                var user = users[index];

                return ListTile(
                  title: Text(user['username']),
                  onTap: () {
                    // Navigate to the chat page with the selected user
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ChatPage(
                        userId: user['id'],
                        username: user['username'],
                      ),
                    ));
                  },
                );
              },
            ),
    );
  }
}
