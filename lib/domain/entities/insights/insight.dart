import '../../../core/enums/insight_category.dart';
import '../../../core/enums/insight_priority.dart';
import '../../../core/enums/insight_type.dart';

class Insight {
  const Insight({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.message,
    required this.data,
    required this.priority,
    required this.isRead,
    required this.isDismissed,
    required this.validUntil,
    required this.generatedAt,
  });
  final int id;
  final InsightType type;
  final InsightCategory category;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final InsightPriority priority;
  final bool isRead;
  final bool isDismissed;
  final DateTime validUntil;
  final DateTime generatedAt;

  Insight copyWith({
    int? id,
    InsightType? type,
    InsightCategory? category,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    InsightPriority? priority,
    bool? isRead,
    bool? isDismissed,
    DateTime? validUntil,
    DateTime? generatedAt,
  }) {
    return Insight(
      id: id ?? this.id,
      type: type ?? this.type,
      category: category ?? this.category,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      isDismissed: isDismissed ?? this.isDismissed,
      validUntil: validUntil ?? this.validUntil,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Insight &&
        other.id == id &&
        other.type == type &&
        other.category == category &&
        other.title == title &&
        other.message == message &&
        // Basic map equality for data
        other.data.length == data.length &&
        other.data.keys.every((k) => other.data[k] == data[k]) &&
        other.priority == priority &&
        other.isRead == isRead &&
        other.isDismissed == isDismissed &&
        other.validUntil == validUntil &&
        other.generatedAt == generatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        type.hashCode ^
        category.hashCode ^
        title.hashCode ^
        message.hashCode ^
        data.hashCode ^
        priority.hashCode ^
        isRead.hashCode ^
        isDismissed.hashCode ^
        validUntil.hashCode ^
        generatedAt.hashCode;
  }

  @override
  String toString() {
    return 'Insight(id: $id, type: $type, category: $category, title: $title, message: $message, data: $data, priority: $priority, isRead: $isRead, isDismissed: $isDismissed, validUntil: $validUntil, generatedAt: $generatedAt)';
  }
}
