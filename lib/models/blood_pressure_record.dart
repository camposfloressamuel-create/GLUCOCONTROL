enum BloodPressureCategory {
  low('Presión baja (referencia)'),
  normal('En rango de referencia'),
  elevated('Ligeramente elevada'),
  high('Por encima de referencia');

  final String label;
  const BloodPressureCategory(this.label);
}

class BloodPressureRecord {
  final int? id;
  final int systolic;
  final int diastolic;
  final int pulse;
  final DateTime measuredAt;
  final String? notes;
  final DateTime createdAt;

  const BloodPressureRecord({
    this.id,
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.measuredAt,
    this.notes,
    required this.createdAt,
  });

  BloodPressureRecord copyWith({
    int? id,
    int? systolic,
    int? diastolic,
    int? pulse,
    DateTime? measuredAt,
    String? notes,
    DateTime? createdAt,
  }) {
    return BloodPressureRecord(
      id: id ?? this.id,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      pulse: pulse ?? this.pulse,
      measuredAt: measuredAt ?? this.measuredAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Clasificación puramente informativa (no constituye diagnóstico médico).
  BloodPressureCategory get category {
    if (systolic < 90 || diastolic < 60) {
      return BloodPressureCategory.low;
    }
    if (systolic < 120 && diastolic < 80) {
      return BloodPressureCategory.normal;
    }
    if (systolic < 130 && diastolic < 85) {
      return BloodPressureCategory.elevated;
    }
    return BloodPressureCategory.high;
  }

  /// Índice normalizado (0..3) para ubicar el marcador en la barra visual.
  int get visualSegmentIndex {
    switch (category) {
      case BloodPressureCategory.low:
        return 0;
      case BloodPressureCategory.normal:
        return 1;
      case BloodPressureCategory.elevated:
        return 2;
      case BloodPressureCategory.high:
        return 3;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'systolic': systolic,
      'diastolic': diastolic,
      'pulse': pulse,
      'measured_at': measuredAt.toIso8601String(),
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory BloodPressureRecord.fromMap(Map<String, dynamic> map) {
    return BloodPressureRecord(
      id: map['id'] as int?,
      systolic: (map['systolic'] as num).toInt(),
      diastolic: (map['diastolic'] as num).toInt(),
      pulse: (map['pulse'] as num).toInt(),
      measuredAt: DateTime.parse(map['measured_at'] as String),
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }
}
