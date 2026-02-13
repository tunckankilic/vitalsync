import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/enums/insight_category.dart';
import '../../../core/enums/insight_priority.dart';
import '../../../core/enums/insight_type.dart';
import '../../../domain/entities/insights/insight.dart';
import '../../local/database.dart';

/// Insight Model.
class InsightModel extends Insight {
  const InsightModel({
    required super.id,
    required super.type,
    required super.category,
    required super.title,
    required super.message,
    required super.data,
    required super.priority,
    required super.isRead,
    required super.isDismissed,
    required super.validUntil,
    required super.generatedAt,
  });

  factory InsightModel.fromJson(Map<String, dynamic> json) {
    return InsightModel(
      id: json['id'] as int? ?? 0,
      type: InsightType.values.firstWhere((e) => e.name == json['type']),
      category: InsightCategory.values.firstWhere(
        (e) => e.name == json['category'],
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>,
      priority: InsightPriority.values.firstWhere(
        (e) => e.name == json['priority'],
      ),
      isRead: json['isRead'] as bool,
      isDismissed: json['isDismissed'] as bool,
      validUntil: DateTime.parse(json['validUntil'] as String),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }

  factory InsightModel.fromEntity(Insight entity) {
    return InsightModel(
      id: entity.id,
      type: entity.type,
      category: entity.category,
      title: entity.title,
      message: entity.message,
      data: entity.data,
      priority: entity.priority,
      isRead: entity.isRead,
      isDismissed: entity.isDismissed,
      validUntil: entity.validUntil,
      generatedAt: entity.generatedAt,
    );
  }

  factory InsightModel.fromDrift(GeneratedInsightData data) {
    return InsightModel(
      id: data.id,
      type: data.insightType,
      category: data.category,
      title: data.title,
      message: data.message,
      data: jsonDecode(data.data) as Map<String, dynamic>,
      priority: InsightPriority.values.elementAt(data.priority),
      isRead: data.isRead,
      isDismissed: data.isDismissed,
      validUntil: data.validUntil,
      generatedAt: data.generatedAt,
    );
  }

  Insight toEntity() {
    return Insight(
      id: id,
      type: type,
      category: category,
      title: title,
      message: message,
      data: data,
      priority: priority,
      isRead: isRead,
      isDismissed: isDismissed,
      validUntil: validUntil,
      generatedAt: generatedAt,
    );
  }

  GeneratedInsightsCompanion toCompanion() {
    return GeneratedInsightsCompanion(
      id: Value(id),
      insightType: Value(type),
      category: Value(category),
      title: Value(title),
      message: Value(message),
      data: Value(jsonEncode(data)),
      priority: Value(priority.index),
      isRead: Value(isRead),
      isDismissed: Value(isDismissed),
      validUntil: Value(validUntil),
      generatedAt: Value(generatedAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'category': category.name,
      'title': title,
      'message': message,
      'data': data,
      'priority': priority.name,
      'isRead': isRead,
      'isDismissed': isDismissed,
      'validUntil': validUntil.toIso8601String(),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}
