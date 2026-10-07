import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Read operations are app-reported. Writes are recorded by the trusted
/// Firestore trigger, including batches, transactions and external imports.
class ActivityLogService {
  ActivityLogService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    Future<void> Function(Map<String, dynamic>)? writer,
    Map<String, String>? actor,
  }) : _firestore = firestore,
       _auth = auth,
       _writer = writer,
       _actor = actor;

  static final instance = ActivityLogService();
  static final Object _readScope = Object();
  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;
  final Future<void> Function(Map<String, dynamic>)? _writer;
  final Map<String, String>? _actor;

  Future<T> trackRead<T>({
    required String module,
    required String operation,
    required Future<T> Function() body,
    String documentId = '',
  }) async {
    // One log for a public operation, rather than one per nested lookup/query.
    if (Zone.current[_readScope] == true) return body();
    final actor = _captureActor();
    return runZoned(() async {
      T result;
      try {
        result = await body();
      } catch (_) {
        await _record(actor, module, operation, documentId, 'failure', 0);
        rethrow;
      }
      Object? value = result;
      final failed = result is Either && result.isLeft();
      if (result is Either) value = result.fold((_) => null, (right) => right);
      final count = value is Iterable
          ? value.length
          : value == null
          ? 0
          : 1;
      await _record(
        actor,
        module,
        operation,
        documentId,
        failed ? 'failure' : 'success',
        count,
      );
      return result;
    }, zoneValues: {_readScope: true});
  }

  Map<String, String>? _captureActor() {
    if (_actor != null) return Map.of(_actor);
    try {
      final user = (_auth ?? FirebaseAuth.instance).currentUser;
      if (user == null) return null;
      return {
        'uid': user.uid,
        'name': user.displayName ?? user.email ?? user.uid,
        'email': user.email ?? '',
      };
    } catch (_) {
      // No Firebase app in isolated unit tests or before app initialization.
      return null;
    }
  }

  Future<void> _record(
    Map<String, String>? actor,
    String module,
    String operation,
    String documentId,
    String status,
    int count,
  ) async {
    if (actor == null) return;
    final entry = <String, dynamic>{
      'schemaVersion': 1,
      'source': 'app_read',
      'action': 'read',
      'module': module,
      'operation': operation,
      'documentId': documentId,
      'actorUid': actor['uid'],
      'actorName': actor['name'] ?? '',
      'actorEmail': actor['email'] ?? '',
      'status': status,
      'resultCount': count,
      'createdAt': FieldValue.serverTimestamp(),
    };
    try {
      final write = _writer;
      if (write != null) {
        await write(entry).timeout(const Duration(seconds: 3));
      } else {
        await (_firestore ?? FirebaseFirestore.instance)
            .collection('audit_logs')
            .add(entry)
            .timeout(const Duration(seconds: 3));
      }
    } catch (error) {
      // Logging must never turn a successful business read into an error.
      debugPrint('Activity read log could not be recorded: $error');
    }
  }
}
