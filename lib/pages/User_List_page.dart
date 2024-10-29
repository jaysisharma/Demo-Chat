import 'package:app/pages/login_page.dart';
import 'package:app/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'inbox.dart'; // Ensure you have the correct import for InboxPage

class UserListPage extends StatefulWidget {
  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> addedUsers = []; // Store added users
  String? currentUserId; // Store current user ID

  @override
  void initState() {
    super.initState();
    // Get the current user's ID
    currentUserId = _auth.currentUser?.uid;
    print('Current User ID: $currentUserId');
    // Load added users from Firestore
    if (currentUserId != null) {
      _loadAddedUsers();
    }
  }

  void _loadAddedUsers() async {
    // Load the list of added users from Firestore
    var doc = await _firestore.collection('users').doc(currentUserId).collection('friends').get();
    setState(() {
      addedUsers = doc.docs.map((friend) => {
        'id': friend.id,
        'username': friend['username'],
      }).toList();
    });
  }

  void _logout(BuildContext context) async {
    await _authService.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false,
    );
  }

  void _addFriend(String userId, String username) async {
    // Add user to the addedUsers list and save to Firestore
    setState(() {
      addedUsers.add({'id': userId, 'username': username});
    });

    // Save to Firestore
    await _firestore.collection('users').doc(currentUserId).collection('friends').doc(userId).set({
      'username': username,
    });

    // Show a confirmation message or snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$username added to your friends!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Users'),
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: Icon(Icons.logout),
          onPressed: () {
            _logout(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: () {
              // Navigate to the Inbox Page to view added users
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InboxPage(users: addedUsers),
                ),
              );
            },
          )
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.isEmpty) {
            return Center(child: Text('No users available'));
          }

          // Filter out the current user and users that have already been added
          final availableUsers = snapshot.data!.where((user) {
            return user['id'] != currentUserId && // Exclude the current user
                !addedUsers.any((addedUser) =>
                    addedUser['id'] == user['id']); // Exclude already added users
          }).toList();

          // Debug print statements
          print('Available Users: $availableUsers');

          return ListView.builder(
            itemCount: availableUsers.length,
            itemBuilder: (context, index) {
              var user = availableUsers[index];

              return ListTile(
                title: Text(user['username']),
                trailing: ElevatedButton(
                  child: Text('Add User'),
                  onPressed: () {
                    _addFriend(user['id'], user['username']); // Add user to the list and Firestore
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> getUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => {
        'id': doc.id, // Add user ID
        'username': doc['username'],
      }).toList();
    });
  }
}
