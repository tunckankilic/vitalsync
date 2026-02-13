import '../../../core/enums/gender.dart';

/// User Profile Entity.
///
/// Represents the user's core profile information.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.firebaseUid,
    required this.name,
    required this.gdprConsentVersion,
    required this.gdprConsentDate,
    required this.createdAt,
    required this.updatedAt,
    this.birthDate,
    this.gender = Gender.preferNotToSay,
    this.locale = 'en',
    this.emergencyContact,
    this.emergencyPhone,
  });
  final int id;
  final String firebaseUid;
  final String name;
  final DateTime? birthDate;
  final Gender gender;
  final String locale;
  final String? emergencyContact;
  final String? emergencyPhone;
  final String gdprConsentVersion;
  final DateTime gdprConsentDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Creates a copy of this UserProfile with the given fields replaced with the new values.
  UserProfile copyWith({
    int? id,
    String? firebaseUid,
    String? name,
    DateTime? birthDate,
    Gender? gender,
    String? locale,
    String? emergencyContact,
    String? emergencyPhone,
    String? gdprConsentVersion,
    DateTime? gdprConsentDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      locale: locale ?? this.locale,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      gdprConsentVersion: gdprConsentVersion ?? this.gdprConsentVersion,
      gdprConsentDate: gdprConsentDate ?? this.gdprConsentDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserProfile &&
        other.id == id &&
        other.firebaseUid == firebaseUid &&
        other.name == name &&
        other.birthDate == birthDate &&
        other.gender == gender &&
        other.locale == locale &&
        other.emergencyContact == emergencyContact &&
        other.emergencyPhone == emergencyPhone &&
        other.gdprConsentVersion == gdprConsentVersion &&
        other.gdprConsentDate == gdprConsentDate &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        firebaseUid.hashCode ^
        name.hashCode ^
        birthDate.hashCode ^
        gender.hashCode ^
        locale.hashCode ^
        emergencyContact.hashCode ^
        emergencyPhone.hashCode ^
        gdprConsentVersion.hashCode ^
        gdprConsentDate.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, firebaseUid: $firebaseUid, name: $name, birthDate: $birthDate, gender: $gender, locale: $locale, emergencyContact: $emergencyContact, emergencyPhone: $emergencyPhone, gdprConsentVersion: $gdprConsentVersion, gdprConsentDate: $gdprConsentDate, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
