import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to send a message
  Future<void> sendMessage(String senderId, String receiverId, String message) async {
    // Send the message
    await _firestore.collection('messages').add({
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update last message for both sender and receiver
    await _updateLastMessage(senderId, receiverId, message);
    await _updateLastMessage(receiverId, senderId, message); // Also update on receiver's end
  }

  // Function to update the last message in the user's chat list
  Future<void> _updateLastMessage(String userId, String chatPartnerId, String lastMessage) async {
    await _firestore.collection('users').doc(userId).collection('chatList').doc(chatPartnerId).set({
      'lastMessage': lastMessage,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Function to get messages between two users
  Stream<List<Map<String, dynamic>>> getMessages(String currentUserId, String chatPartnerId) {
    // Stream for sent messages
    final sentMessagesStream = _firestore
        .collection('messages')
        .where('senderId', isEqualTo: currentUserId)
        .where('receiverId', isEqualTo: chatPartnerId)
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());

    // Stream for received messages
    final receivedMessagesStream = _firestore
        .collection('messages')
        .where('senderId', isEqualTo: chatPartnerId)
        .where('receiverId', isEqualTo: currentUserId)
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());

    // Combine sent and received messages streams
    return Rx.combineLatest2(sentMessagesStream, receivedMessagesStream, (List<Map<String, dynamic>> sentMessages, List<Map<String, dynamic>> receivedMessages) {
      // Combine both lists and sort them by timestamp
      final allMessages = [...sentMessages, ...receivedMessages];
      allMessages.sort((a, b) => a['timestamp'].compareTo(b['timestamp'])); // Sort by timestamp
      return allMessages; // Return combined and sorted messages
    });
  }

  // Function to get a list of users
  Stream<List<Map<String, dynamic>>> getUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    });
  }

  // Function to get chat list for a specific user
  // Function to get chat list for a specific user
Stream<List<Map<String, dynamic>>> getChatList(String userId) {
  return _firestore.collection('users').doc(userId).collection('chatList').snapshots().asyncMap((snapshot) async {
    final List<Map<String, dynamic>> chatList = [];

    for (var doc in snapshot.docs) {
      final chatPartnerId = doc.id; // Get the ID of the chat partner
      final lastMessage = doc['lastMessage'] ?? 'No messages yet'; // Fallback if null
      final userDoc = await _firestore.collection('users').doc(chatPartnerId).get(); // Fetch user details
      final username = userDoc.data()?['username'] ?? 'Unknown'; // Get username, fallback if null

      chatList.add({
        'id': chatPartnerId,
        'username': username,
        'lastMessage': lastMessage,
        'timestamp': doc['timestamp'],
      });
    }
    return chatList; // Return the updated chat list with usernames
  });
}

}
