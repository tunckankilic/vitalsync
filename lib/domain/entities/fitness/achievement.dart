import '../../../core/enums/achievement_type.dart';

class Achievement {
  const Achievement({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.requirement,
    required this.iconName,
    this.unlockedAt,
  });

  final int id;
  final AchievementType type;
  final String title;
  final String description;
  final int requirement;
  final DateTime? unlockedAt;
  final String iconName;

  Achievement copyWith({
    int? id,
    AchievementType? type,
    String? title,
    String? description,
    int? requirement,
    DateTime? unlockedAt,
    String? iconName,
  }) {
    return Achievement(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      requirement: requirement ?? this.requirement,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      iconName: iconName ?? this.iconName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Achievement &&
        other.id == id &&
        other.type == type &&
        other.title == title &&
        other.description == description &&
        other.requirement == requirement &&
        other.unlockedAt == unlockedAt &&
        other.iconName == iconName;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        type.hashCode ^
        title.hashCode ^
        description.hashCode ^
        requirement.hashCode ^
        unlockedAt.hashCode ^
        iconName.hashCode;
  }

  @override
  String toString() {
    return 'Achievement(id: $id, type: $type, title: $title, description: $description, requirement: $requirement, unlockedAt: $unlockedAt, iconName: $iconName)';
  }
}
