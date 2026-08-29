import '../../domain/entities/agency_insight.dart';
import '../../domain/entities/agency_insight_item.dart';

class AgencyInsightItemModel {
  final String level;
  final String title;
  final String message;
  final String relatedTo;

  const AgencyInsightItemModel({
    required this.level,
    required this.title,
    required this.message,
    required this.relatedTo,
  });

  factory AgencyInsightItemModel.fromJson(Map<String, dynamic> json) {
    return AgencyInsightItemModel(
      level: json['level'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      relatedTo: json['related_to'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'title': title,
      'message': message,
      'related_to': relatedTo,
    };
  }

  AgencyInsightItem toEntity() {
    return AgencyInsightItem(
      level: level,
      title: title,
      message: message,
      relatedTo: relatedTo,
    );
  }
}

class AgencyInsightModel {
  final int id;
  final int agencyId;
  final String granularity;
  final String startDate;
  final String endDate;
  final Map<String, dynamic> digest;
  final List<AgencyInsightItemModel> insights;
  final String? model;
  final String? digestHash;
  final String generatedAt;
  const AgencyInsightModel({
    required this.id,
    required this.agencyId,
    required this.granularity,
    required this.startDate,
    required this.endDate,
    required this.digest,
    required this.insights,
    this.model,
    this.digestHash,
    required this.generatedAt,
  });

  /// Convertit le JSON de l'API Laravel en Model Dart
  factory AgencyInsightModel.fromJson(Map<String, dynamic> json) {
    final period = json['period'] as Map<String, dynamic>? ?? {};

    return AgencyInsightModel(
      id: json['id'] as int,
      agencyId: json['agency_id'] as int,
      granularity: json['granularity'] as String,
      startDate: period['start_date'] as String,
      endDate: period['end_date'] as String,
      digest: (json['digest'] as Map<String, dynamic>?) ?? {},
      insights: (json['insights'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                AgencyInsightItemModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      model: json['model'] as String?,
      digestHash: json['digest_hash'] as String?,
      generatedAt: json['generated_at'] as String,
    );
  }

  /// Conversion du Model vers le JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agency_id': agencyId,
      'granularity': granularity,
      'period': {'start_date': startDate, 'end_date': endDate},
      'digest': digest,
      'insights': insights.map((item) => item.toJson()).toList(),
      'model': model,
      'digest_hash': digestHash,
      'generated_at': generatedAt,
    };
  }

  /// Transforme ce modèle de données en entité métier pure pour le domaine
  AgencyInsight toEntity() {
    return AgencyInsight(
      id: id,
      agencyId: agencyId,
      granularity: granularity,
      startDate: DateTime.parse(startDate),
      endDate: DateTime.parse(endDate),
      digest: digest,
      insights: insights.map((item) => item.toEntity()).toList(),
      model: model,
      digestHash: digestHash,
      generatedAt: DateTime.parse(generatedAt),
    );
  }
}
