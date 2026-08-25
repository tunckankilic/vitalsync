/// VitalSync — Meals Table (Health Module).
library;

import 'package:drift/drift.dart';

import '../../../../core/enums/sync_status.dart';

/// Meals logged by the user.
///
/// Photo-free by design: a meal is a time, a name, tags and an optional note.
/// No image is captured or stored, and no nutritional estimate is derived.
@DataClassName('MealData')
class Meals extends Table {
  /// Primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Meal name as typed by the user (e.g. "Oatmeal with banana").
  TextColumn get name => text()();

  /// When the meal was eaten.
  DateTimeColumn get eatenAt => dateTime()();

  /// Additional notes about the meal.
  TextColumn get notes => text().nullable()();

  /// JSON array of tags for categorization.
  /// Example: ["breakfast", "home_cooked"]
  TextColumn get tags => text()();

  /// Sync status for offline-first architecture.
  /// Stored as string, converted to/from SyncStatus enum.
  TextColumn get syncStatus =>
      textEnum<SyncStatus>().withDefault(const Constant('synced'))();

  /// Last modification timestamp for conflict resolution.
  DateTimeColumn get lastModifiedAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
