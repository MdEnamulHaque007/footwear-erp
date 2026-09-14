import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/config/dev_config.dart';
import '../../core/services/local/local_settings_service.dart';
import '../../domain/entities/settings/app_settings_entity.dart';
import '../../domain/entities/settings/business_settings_entity.dart';
import '../../domain/repositories/i_settings_repository.dart';
import '../models/settings/app_settings_model.dart';
import '../models/settings/business_settings_model.dart';

class SettingsRepository implements ISettingsRepository {
  SettingsRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required LocalSettingsService localService,
  }) : _firestore = firestore,
       _auth = auth,
       _localService = localService;

  static const String _collectionUsers = 'users';
  static const String _collectionSettings = 'settings';
  static const String _collectionPreferences = 'preferences';
  static const String _docApp = 'app';
  static const String _docBusiness = 'business';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final LocalSettingsService _localService;

  @override
  Future<Either<String, AppSettingsEntity>> getAppSettings() async {
    try {
      final local = await _localService.getAppSettings();
      if (local != null) return Right(local);

      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        final document = await _firestore
            .collection(_collectionUsers)
            .doc(uid)
            .collection(_collectionPreferences)
            .doc(_docApp)
            .get();
        final data = document.data();
        if (document.exists && data != null) {
          final model = AppSettingsModel.fromJson(data);
          await _localService.saveAppSettings(model);
          return Right(model);
        }
      }

      final defaults = AppSettingsEntity.defaults();
      await _localService.saveAppSettings(defaults);
      return Right(defaults);
    } catch (error) {
      return Left('Failed to load app settings: $error');
    }
  }

  @override
  Future<Either<String, void>> saveAppSettings(AppSettingsEntity entity) async {
    try {
      await _localService.saveAppSettings(entity);

      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        final model = AppSettingsModel.fromEntity(entity);
        await _firestore
            .collection(_collectionUsers)
            .doc(uid)
            .collection(_collectionPreferences)
            .doc(_docApp)
            .set(model.toJson(), SetOptions(merge: true));
      }
      return const Right(null);
    } catch (error) {
      return Left('Failed to save app settings: $error');
    }
  }

  @override
  Future<Either<String, BusinessSettingsEntity>> getBusinessSettings() async {
    try {
      if (DevConfig.bypassAuth) {
        final local = await _localService.getBusinessSettings();
        if (local != null) return Right(local);
        final defaults = BusinessSettingsEntity.defaults();
        await _localService.saveBusinessSettings(defaults);
        return Right(defaults);
      }

      final document = await _firestore
          .collection(_collectionSettings)
          .doc(_docBusiness)
          .get();
      final data = document.data();
      if (!document.exists || data == null) {
        return Right(BusinessSettingsEntity.defaults());
      }
      return Right(BusinessSettingsModel.fromJson(data));
    } catch (error) {
      return Left('Failed to load business settings: $error');
    }
  }

  @override
  Future<Either<String, void>> saveBusinessSettings(
    BusinessSettingsEntity entity,
  ) async {
    try {
      if (DevConfig.bypassAuth) {
        await _localService.saveBusinessSettings(entity);
        return const Right(null);
      }

      final reference = _firestore
          .collection(_collectionSettings)
          .doc(_docBusiness);
      final model = BusinessSettingsModel.fromEntity(entity);
      await _firestore.runTransaction<void>((transaction) async {
        transaction.set(reference, model.toJson(), SetOptions(merge: true));
      });
      return const Right(null);
    } catch (error) {
      return Left('Failed to save business settings: $error');
    }
  }
}
