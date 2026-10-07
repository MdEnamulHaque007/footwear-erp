import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../config/dev_config.dart';

/// Implements Firebase's HTTPS callable protocol without an extra SDK package.
/// Business C/U/D is authorized and validated on the server, never by fallback
/// direct writes. Firebase credentials are sent only to this app's endpoint.
class FirebaseCloudFunctionService {
  FirebaseCloudFunctionService({Dio? client, FirebaseAuth? auth})
    : _client = client ?? Dio(),
      _auth = auth;
  static final instance = FirebaseCloudFunctionService();
  final Dio _client;
  final FirebaseAuth? _auth;

  Future<Map<String, dynamic>> call(
    String name, [
    Map<String, dynamic>? parameters,
  ]) async {
    final user = (_auth ?? FirebaseAuth.instance).currentUser;
    if (user == null)
      throw FirebaseException(
        plugin: 'cloud_functions',
        code: 'unauthenticated',
        message: 'Sign in first.',
      );
    final project = Firebase.app().options.projectId;
    final endpoint = DevConfig.useFirebaseEmulator
        ? 'http://${DevConfig.emulatorHost}:5001/$project/us-central1/$name'
        : 'https://us-central1-$project.cloudfunctions.net/$name';
    final token = await user.getIdToken();
    try {
      final response = await _client.post<Map<String, dynamic>>(
        endpoint,
        data: {'data': _encode(parameters ?? {})},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 120),
          validateStatus: (status) => status != null && status < 600,
        ),
      );
      final body = response.data ?? {};
      final error = body['error'];
      if (error is Map) {
        throw FirebaseException(
          plugin: 'cloud_functions',
          code: (error['status']?.toString() ?? 'unknown')
              .toLowerCase()
              .replaceAll('_', '-'),
          message:
              error['message']?.toString() ?? 'The operation was rejected.',
        );
      }
      final result = body['result'] ?? body['data'];
      if (response.statusCode != 200 || result is! Map) {
        throw FirebaseException(
          plugin: 'cloud_functions',
          code: 'unavailable',
          message: 'Server functions are unavailable. Deploy mutateBusiness/bootstrapAdmin before using this release.',
        );
      }
      return Map<String, dynamic>.from(result);
    } on DioException {
      throw FirebaseException(
        plugin: 'cloud_functions',
        code: 'unavailable',
        message: 'Unable to reach the ERP server. Check your connection and server deployment.',
      );
    }
  }

  Future<Either<String, void>> mutate({
    required String collection,
    required String action,
    required String id,
    Map<String, dynamic>? data,
  }) async {
    try {
      await call('mutateBusiness', {
        'collection': collection,
        'action': action,
        'id': id,
        'data': data,
      });
      return const Right(null);
    } on FirebaseException catch (error) {
      return Left(error.message ?? 'The operation failed.');
    } catch (_) {
      return const Left('Unable to complete the server operation.');
    }
  }

  static dynamic _encode(dynamic value) {
    if (value is Timestamp)
      return {'__erpTimestamp': value.millisecondsSinceEpoch};
    if (value is DateTime)
      return {'__erpTimestamp': value.millisecondsSinceEpoch};
    if (value is Map)
      return value.map(
        (key, value) => MapEntry(key.toString(), _encode(value)),
      );
    if (value is Iterable) return value.map(_encode).toList();
    return value;
  }
}
