import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
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
      // A first-time login has no profile document yet, so the merge write is
      // denied. That is expected and must not block the sign-in itself.
      debugPrint('Unable to update lastLogin: $error');
    }
    final profile = await _safeLoadProfile(user);
    if (profile == null) throw FirebaseAuthException(code: 'user-null');
    return profile;
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

  Future<UserModel> updateDisplayName(String displayName) async {
    final name = displayName.trim();
    if (name.isEmpty) {
      throw ArgumentError.value(displayName, 'displayName', 'Name is required');
    }
    final user = _auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'user-not-signed-in');

    await user.updateDisplayName(name).timeout(const Duration(seconds: 10));
    await _firestore
        .collection(AppConstants.collectionUsers)
        .doc(user.uid)
        .update({'displayName': name})
        .timeout(const Duration(seconds: 10));

    final profile = await _safeLoadProfile(user);
    if (profile == null) throw FirebaseAuthException(code: 'user-null');
    return profile;
  }

  /// Loads the Firestore profile, distinguishing the three outcomes that the
  /// rest of the app must react to differently:
  ///
  /// * profile present → return it;
  /// * profile missing → [ProfileMissingException] (the account can sign in but
  ///   holds no authorisation, so every Firestore rule will deny — the UI must
  ///   say so instead of showing an empty list);
  /// * profile unreadable (denied / offline) → [ProfileUnavailableException].
  ///
  /// Previously both failure modes returned a bare `UserModel.fromFirebase`
  /// fallback, which made a permission problem indistinguishable from a normal
  /// login with no data — the root cause of the ambiguous
  /// "Missing or insufficient permissions" report.
  Future<UserModel?> _loadProfile(User? user) async {
    if (user == null) return null;
    final snapshot = await _firestore
        .collection(AppConstants.collectionUsers)
        .doc(user.uid)
        .get()
        .timeout(const Duration(seconds: 10));
    if (!snapshot.exists) {
      throw ProfileMissingException(user.uid);
    }
    return UserModel.fromFirestore(snapshot);
  }

  Future<UserModel?> _safeLoadProfile(User? user) async {
    if (user == null) return null;
    try {
      return await _loadProfile(
        user,
      ).timeout(const Duration(seconds: 10), onTimeout: () => null);
    } on ProfileMissingException {
      // Let the caller decide (the bootstrap flow needs to see this).
      rethrow;
    } catch (error) {
      debugPrint('Unable to load Firestore profile for ${user.uid}: $error');
      throw ProfileUnavailableException(user.uid, error);
    }
  }

  /// Creates the signed-in account's own `users/{uid}` profile as the first
  /// admin. Used once, on initial setup.
  ///
  /// A **single** write: the profile is created complete. An earlier version
  /// wrote a transient `bootstrap: true` marker and then deleted it in a second
  /// call, but that second write was denied by the `update` rule (which only
  /// allows `lastLogin` / `displayName`) and was mis-reported as "an admin
  /// profile already exists" — even though the profile had in fact been
  /// created. Writing once removes the failure mode entirely.
  ///
  /// Returns [Left] with a readable message when the rules reject the write,
  /// which happens once an admin profile already exists.
  Future<Either<String, UserModel>> bootstrapAdminProfile({
    required String displayName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return const Left('You must be signed in to create the admin profile.');
    }
    final name = displayName.trim().isEmpty
        ? 'System Admin'
        : displayName.trim();
    try {
      final doc = _firestore
          .collection(AppConstants.collectionUsers)
          .doc(user.uid);
      final model = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: name,
        role: AppConstants.roleAdmin,
        permissions: const {},
        isEmailVerified: user.emailVerified,
        isActive: true,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );
      await doc.set(model.toFirestore()).timeout(const Duration(seconds: 10));
      return Right(model);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return const Left(
          'An admin profile already exists, so the bootstrap is no longer '
          'allowed. Ask an existing admin to grant you access.',
        );
      }
      return Left('Unable to create the admin profile: ${e.message}');
    } catch (_) {
      return const Left('Unable to create the admin profile.');
    }
  }

  Future<void> _updateLastLogin(String uid) => _firestore
      .collection(AppConstants.collectionUsers)
      .doc(uid)
      .set({'lastLogin': Timestamp.now()}, SetOptions(merge: true))
      .timeout(const Duration(seconds: 10));
}

/// The account authenticated with Firebase Auth but has no `users/{uid}`
/// profile document, so no Firestore rule can authorise it.
class ProfileMissingException implements Exception {
  const ProfileMissingException(this.uid);
  final String uid;

  @override
  String toString() =>
      'Your account has no profile yet. Create the administrator profile to '
      'continue.';
}

/// The profile exists but could not be read (permission denied or offline).
class ProfileUnavailableException implements Exception {
  const ProfileUnavailableException(this.uid, this.cause);
  final String uid;
  final Object cause;

  @override
  String toString() =>
      'Unable to load your profile. Check your connection and permissions.';
}
