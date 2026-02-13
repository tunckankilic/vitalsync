import 'package:drift/drift.dart';

import '../../../core/enums/gender.dart';
import '../../../domain/entities/shared/user_profile.dart';
import '../../local/database.dart';

/// User Profile Model.
///
/// Data transfer object for UserProfile, handles serialization and DB mapping.
class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.firebaseUid,
    required super.name,
    required super.gdprConsentVersion,
    required super.gdprConsentDate,
    required super.createdAt,
    required super.updatedAt,
    super.birthDate,
    super.gender,
    super.locale,
    super.emergencyContact,
    super.emergencyPhone,
  });

  /// Creates a UserProfileModel from a UserProfile entity.
  factory UserProfileModel.fromEntity(UserProfile entity) {
    return UserProfileModel(
      id: entity.id,
      firebaseUid: entity.firebaseUid,
      name: entity.name,
      birthDate: entity.birthDate,
      gender: entity.gender,
      locale: entity.locale,
      emergencyContact: entity.emergencyContact,
      emergencyPhone: entity.emergencyPhone,
      gdprConsentVersion: entity.gdprConsentVersion,
      gdprConsentDate: entity.gdprConsentDate,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Creates a UserProfileModel from a Drift UserProfileData object.
  factory UserProfileModel.fromDrift(UserProfileData data) {
    return UserProfileModel(
      id: data.id,
      firebaseUid: data.firebaseUid,
      name: data.name,
      birthDate: data.birthDate,
      gender: data.gender,
      locale: data.locale,
      emergencyContact: data.emergencyContact,
      emergencyPhone: data.emergencyPhone,
      gdprConsentVersion: data.gdprConsentVersion,
      gdprConsentDate: data.gdprConsentDate,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }

  /// Creates a UserProfileModel from a JSON map (Firestore).
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as int? ?? 0, // ID might not be in Firestore or different
      firebaseUid: json['firebaseUid'] as String,
      name: json['name'] as String,
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'] as String)
          : null,
      gender: Gender.fromDbValue(json['gender'] as String? ?? 'preferNotToSay'),
      locale: json['locale'] as String? ?? 'en',
      emergencyContact: json['emergencyContact'] as String?,
      emergencyPhone: json['emergencyPhone'] as String?,
      gdprConsentVersion: json['gdprConsentVersion'] as String,
      gdprConsentDate: DateTime.parse(json['gdprConsentDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Converts this model to a UserProfile entity.
  UserProfile toEntity() {
    return UserProfile(
      id: id,
      firebaseUid: firebaseUid,
      name: name,
      birthDate: birthDate,
      gender: gender,
      locale: locale,
      emergencyContact: emergencyContact,
      emergencyPhone: emergencyPhone,
      gdprConsentVersion: gdprConsentVersion,
      gdprConsentDate: gdprConsentDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Converts this model to a Drift Companion for insertion/updating.
  UserProfilesCompanion toCompanion() {
    return UserProfilesCompanion(
      id: Value(id),
      firebaseUid: Value(firebaseUid),
      name: Value(name),
      birthDate: Value(birthDate),
      gender: Value(gender),
      locale: Value(locale),
      emergencyContact: Value(emergencyContact),
      emergencyPhone: Value(emergencyPhone),
      gdprConsentVersion: Value(gdprConsentVersion),
      gdprConsentDate: Value(gdprConsentDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  /// Converts this model to a JSON map (Firestore).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebaseUid': firebaseUid,
      'name': name,
      'birthDate': birthDate?.toIso8601String(),
      'gender': gender.toDbValue(),
      'locale': locale,
      'emergencyContact': emergencyContact,
      'emergencyPhone': emergencyPhone,
      'gdprConsentVersion': gdprConsentVersion,
      'gdprConsentDate': gdprConsentDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      // Flatten helper fields if needed
    };
  }
}
