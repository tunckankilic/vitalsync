import 'dart:convert';
import 'package:vitalsync/data/local/daos/shared/user_profile_dao.dart';
import 'package:vitalsync/data/local/database.dart';
import 'package:vitalsync/data/models/shared/user_profile_model.dart';
import 'package:vitalsync/domain/entities/shared/user_profile.dart';
import 'package:vitalsync/domain/repositories/shared/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._userDao, this._db);
  final UserDao _userDao;
  final AppDatabase _db;

  @override
  Future<UserProfile?> getCurrentUser() async {
    final result = await _userDao.getCurrentUser();
    return result != null ? UserProfileModel.fromDrift(result) : null;
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    final companion = UserProfileModel.fromEntity(profile).toCompanion();
    // Since only one user profile allowed (currentUser), we can check if exists.
    final existing = await _userDao.getCurrentUser();
    if (existing != null) {
      // Update
      // Use helper to construct Data from Model for update()
      final model = UserProfileModel.fromEntity(profile);
      final data = UserProfileData(
        id: existing.id, // Keep existing ID
        firebaseUid: model.firebaseUid,
        name: model.name,
        birthDate: model.birthDate,
        gender: model.gender,
        locale: model.locale,
        emergencyContact: model.emergencyContact,
        emergencyPhone: model.emergencyPhone,
        gdprConsentVersion: model.gdprConsentVersion,
        gdprConsentDate: model.gdprConsentDate,
        createdAt: existing.createdAt, // Keep original creation date
        updatedAt: DateTime.now(),
      );
      await _userDao.updateUser(data);
    } else {
      // Insert
      await _userDao.insertUser(companion);
    }
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    // Similar to saveProfile update path
    final model = UserProfileModel.fromEntity(profile);
    // Fetch ID or expect ID to be correct in profile
    // If ID is 0, we might need to fetch current user ID.
    var id = model.id;
    if (id == 0) {
      final existing = await _userDao.getCurrentUser();
      if (existing != null) id = existing.id;
    }

    final data = UserProfileData(
      id: id,
      firebaseUid: model.firebaseUid,
      name: model.name,
      birthDate: model.birthDate,
      gender: model.gender,
      locale: model.locale,
      emergencyContact: model.emergencyContact,
      emergencyPhone: model.emergencyPhone,
      gdprConsentVersion: model.gdprConsentVersion,
      gdprConsentDate: model.gdprConsentDate,
      createdAt: model.createdAt,
      updatedAt: DateTime.now(),
    );
    await _userDao.updateUser(data);
  }

  @override
  Future<String> exportAllData() async {
    final data = await _db.exportAllData();
    return jsonEncode(data);
  }

  @override
  Future<void> deleteAllData() {
    return _db.deleteAllData();
  }
}
