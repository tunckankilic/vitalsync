import 'package:vitalsync/domain/entities/shared/user_profile.dart';

abstract class UserRepository {
  Future<UserProfile?> getCurrentUser();
  Future<void> saveProfile(UserProfile profile);
  Future<void> updateProfile(UserProfile profile);
  Future<String> exportAllData();
  Future<void> deleteAllData();
}
