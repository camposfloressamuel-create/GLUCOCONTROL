enum BmiCategory {
  underweight('Peso bajo (referencia)'),
  normal('Peso de referencia'),
  overweight('Sobrepeso (referencia)'),
  obese('IMC elevado (referencia)');

  final String label;
  const BmiCategory(this.label);
}

class WeightRecord {
  final int? id;
  final double weightKg;
  final double heightCm;
  final DateTime measuredAt;
  final String? notes;
  final DateTime createdAt;

  const WeightRecord({
    this.id,
    required this.weightKg,
    required this.heightCm,
    required this.measuredAt,
    this.notes,
    required this.createdAt,
  });

  double get bmi {
    if (heightCm <= 0) return 0;
    final meters = heightCm / 100.0;
    return weightKg / (meters * meters);
  }

  BmiCategory get category {
    final value = bmi;
    if (value < 18.5) return BmiCategory.underweight;
    if (value < 25.0) return BmiCategory.normal;
    if (value < 30.0) return BmiCategory.overweight;
    return BmiCategory.obese;
  }

  int get visualSegmentIndex {
    switch (category) {
      case BmiCategory.underweight:
        return 0;
      case BmiCategory.normal:
        return 1;
      case BmiCategory.overweight:
        return 2;
      case BmiCategory.obese:
        return 3;
    }
  }

  WeightRecord copyWith({
    int? id,
    double? weightKg,
    double? heightCm,
    DateTime? measuredAt,
    String? notes,
    DateTime? createdAt,
  }) {
    return WeightRecord(
      id: id ?? this.id,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      measuredAt: measuredAt ?? this.measuredAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'measured_at': measuredAt.toIso8601String(),
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WeightRecord.fromMap(Map<String, dynamic> map) {
    return WeightRecord(
      id: map['id'] as int?,
      weightKg: (map['weight_kg'] as num).toDouble(),
      heightCm: (map['height_cm'] as num).toDouble(),
      measuredAt: DateTime.parse(map['measured_at'] as String),
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }
}
