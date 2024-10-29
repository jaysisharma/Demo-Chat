import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> register(String email, String password, String username) async {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    UserModel userModel = UserModel(
      uid: userCredential.user!.uid,
      email: email,
      username: username,
    );

    await _firestore.collection('users').doc(userModel.uid).set(userModel.toMap());

    return userModel;
  }

  Future<UserModel?> login(String email, String password) async {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    DocumentSnapshot userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
    return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
