import '../utils/constants.dart';
import '../utils/glucose_converter.dart';

class PatientProfile {
  final int? id;
  final String fullName;
  final DateTime? birthDate;
  final String preferredUnit;
  final double targetMin;
  final double targetMax;
  final DateTime trackingStartDate;
  final DateTime updatedAt;

  const PatientProfile({
    this.id,
    required this.fullName,
    this.birthDate,
    required this.preferredUnit,
    required this.targetMin,
    required this.targetMax,
    required this.trackingStartDate,
    required this.updatedAt,
  });

  PatientProfile copyWith({
    int? id,
    String? fullName,
    DateTime? birthDate,
    bool clearBirthDate = false,
    String? preferredUnit,
    double? targetMin,
    double? targetMax,
    DateTime? trackingStartDate,
    DateTime? updatedAt,
  }) {
    return PatientProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      birthDate: clearBirthDate ? null : (birthDate ?? this.birthDate),
      preferredUnit: preferredUnit ?? this.preferredUnit,
      targetMin: targetMin ?? this.targetMin,
      targetMax: targetMax ?? this.targetMax,
      trackingStartDate: trackingStartDate ?? this.trackingStartDate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Devuelve el rango mínimo expresado en la unidad solicitada.
  double targetMinIn(String unit) {
    return GlucoseConverter.convert(
      value: targetMin,
      fromUnit: preferredUnit,
      toUnit: unit,
    );
  }

  /// Devuelve el rango máximo expresado en la unidad solicitada.
  double targetMaxIn(String unit) {
    return GlucoseConverter.convert(
      value: targetMax,
      fromUnit: preferredUnit,
      toUnit: unit,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'full_name': fullName,
      'birth_date': birthDate?.toIso8601String(),
      'preferred_unit': preferredUnit,
      'target_min': targetMin,
      'target_max': targetMax,
      'tracking_start_date': trackingStartDate.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory PatientProfile.fromMap(Map<String, dynamic> map) {
    final unit = (map['preferred_unit'] as String?) ?? AppConstants.unitMgDl;
    return PatientProfile(
      id: map['id'] as int?,
      fullName: (map['full_name'] as String?)?.trim() ?? '',
      birthDate: map['birth_date'] != null
          ? DateTime.tryParse(map['birth_date'] as String)
          : null,
      preferredUnit: unit,
      targetMin: (map['target_min'] as num?)?.toDouble() ??
          (unit == AppConstants.unitMgDl
              ? AppConstants.defaultMinMgDl
              : AppConstants.defaultMinMmolL),
      targetMax: (map['target_max'] as num?)?.toDouble() ??
          (unit == AppConstants.unitMgDl
              ? AppConstants.defaultMaxMgDl
              : AppConstants.defaultMaxMmolL),
      trackingStartDate: map['tracking_start_date'] != null
          ? (DateTime.tryParse(map['tracking_start_date'] as String) ??
              DateTime.now())
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? (DateTime.tryParse(map['updated_at'] as String) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
