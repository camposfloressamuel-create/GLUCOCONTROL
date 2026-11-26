class WaterRecord {
  final int? id;
  final int amountMl;
  final DateTime loggedAt;

  const WaterRecord({
    this.id,
    required this.amountMl,
    required this.loggedAt,
  });

  WaterRecord copyWith({
    int? id,
    int? amountMl,
    DateTime? loggedAt,
  }) {
    return WaterRecord(
      id: id ?? this.id,
      amountMl: amountMl ?? this.amountMl,
      loggedAt: loggedAt ?? this.loggedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount_ml': amountMl,
      'logged_at': loggedAt.toIso8601String(),
    };
  }

  factory WaterRecord.fromMap(Map<String, dynamic> map) {
    return WaterRecord(
      id: map['id'] as int?,
      amountMl: (map['amount_ml'] as num).toInt(),
      loggedAt: DateTime.parse(map['logged_at'] as String),
    );
  }
}
