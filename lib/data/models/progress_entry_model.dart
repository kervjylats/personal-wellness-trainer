class ProgressEntryModel {
  final String id;
  final String businessId;
  final String clientUserId;
  final DateTime date;
  final List<String> photoUrls;
  final Map<String, double> metrics;
  final String? notes;

  const ProgressEntryModel({
    required this.id,
    required this.businessId,
    required this.clientUserId,
    required this.date,
    this.photoUrls = const [],
    this.metrics = const {},
    this.notes,
  });

  factory ProgressEntryModel.fromJson(Map<String, dynamic> json) {
    return ProgressEntryModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      clientUserId: json['client_user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      photoUrls: (json['photo_urls'] as List<dynamic>?)?.cast<String>() ?? [],
      metrics: (json['metrics'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ??
          {},
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'business_id': businessId,
        'client_user_id': clientUserId,
        'date': date.toIso8601String(),
        'photo_urls': photoUrls,
        'metrics': metrics,
        if (notes != null) 'notes': notes,
      };

  ProgressEntryModel copyWith({
    String? id,
    String? businessId,
    String? clientUserId,
    DateTime? date,
    List<String>? photoUrls,
    Map<String, double>? metrics,
    String? notes,
  }) {
    return ProgressEntryModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      clientUserId: clientUserId ?? this.clientUserId,
      date: date ?? this.date,
      photoUrls: photoUrls ?? this.photoUrls,
      metrics: metrics ?? this.metrics,
      notes: notes ?? this.notes,
    );
  }
}