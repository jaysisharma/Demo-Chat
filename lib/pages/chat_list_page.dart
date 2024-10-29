import 'package:app/services/auth_service.dart';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'chat_page.dart';
import 'login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatListPage extends StatelessWidget {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  // Function to handle logout
  void _logout(BuildContext context) async {
    await _authService.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Chats",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _databaseService.getChatList(currentUserId), // Use getChatList instead of getUsers
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          if (snapshot.data!.isEmpty) {
            return Center(child: Text('No chats available.')); // Handle empty chat list
          }

          final users = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 3,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Text(
                      user['username'] != null && user['username'].isNotEmpty
                          ? user['username'][0].toUpperCase()
                          : 'U', // Default character
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    user['username'] ?? 'Unknown', // Fallback for username
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(user['lastMessage'] ?? "No messages yet"),
                  trailing: Icon(Icons.chat_bubble_outline, color: Colors.grey),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ChatPage(
                        userId: user['id'],
                        username: user['username'] ?? 'Unknown', // Fallback for username
                      ),
                    ));
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _logout(context),
        backgroundColor: Colors.red,
        child: Icon(Icons.logout, color: Colors.white),
      ),
    );
  }
}
