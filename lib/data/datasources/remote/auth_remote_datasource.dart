import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../models/user/user_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<UserModel?> get authStateChanges =>
      _auth.authStateChanges().asyncMap(_safeLoadProfile);

  Future<UserModel> login(String email, String password) async {
    final credential = await _auth
        .signInWithEmailAndPassword(email: email.trim(), password: password)
        .timeout(const Duration(seconds: 10));
    final user = credential.user;
    if (user == null) throw FirebaseAuthException(code: 'user-null');
    try {
      await _updateLastLogin(user.uid);
    } catch (error) {
      debugPrint('Unable to update lastLogin: $error');
    }
    return _safeLoadProfile(user).then((profile) => profile!);
  }

  Future<UserModel> register(String name, String email, String password) async {
    final credential = await _auth
        .createUserWithEmailAndPassword(email: email.trim(), password: password)
        .timeout(const Duration(seconds: 10));
    final user = credential.user;
    if (user == null) throw FirebaseAuthException(code: 'user-null');
    await user
        .updateDisplayName(name.trim())
        .timeout(const Duration(seconds: 10));
    final now = Timestamp.now();
    final model = UserModel(
      uid: user.uid,
      email: user.email ?? email.trim(),
      displayName: name.trim(),
      role: AppConstants.roleViewer,
      permissions: const {},
      isEmailVerified: user.emailVerified,
      isActive: true,
      createdAt: now.toDate(),
      lastLogin: now.toDate(),
    );
    await _firestore
        .collection(AppConstants.collectionUsers)
        .doc(user.uid)
        .set(model.toFirestore())
        .timeout(const Duration(seconds: 10));
    return model;
  }

  Future<void> logout() => _auth.signOut();

  Future<UserModel?> currentUser() async {
    try {
      return await _safeLoadProfile(_auth.currentUser);
    } catch (_) {
      return null;
    }
  }

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<UserModel?> _loadProfile(User? user) async {
    if (user == null) return null;
    final snapshot = await _firestore
        .collection(AppConstants.collectionUsers)
        .doc(user.uid)
        .get()
        .timeout(const Duration(seconds: 10));
    return snapshot.exists
        ? UserModel.fromFirestore(snapshot)
        : UserModel.fromFirebase(user, null);
  }

  Future<UserModel?> _safeLoadProfile(User? user) async {
    if (user == null) return null;
    try {
      return await _loadProfile(
        user,
      ).timeout(const Duration(seconds: 10), onTimeout: () => null);
    } catch (_) {
      debugPrint('Unable to load Firestore profile for ${user.uid}');
      return UserModel.fromFirebase(user, null);
    }
  }

  Future<void> _updateLastLogin(String uid) => _firestore
      .collection(AppConstants.collectionUsers)
      .doc(uid)
      .set({'lastLogin': Timestamp.now()}, SetOptions(merge: true))
      .timeout(const Duration(seconds: 10));
}
