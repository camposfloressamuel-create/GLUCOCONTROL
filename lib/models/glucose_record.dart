import '../utils/constants.dart';
import '../utils/glucose_converter.dart';
import 'patient_profile.dart';

enum MeasurementType {
  fasting('en_ayunas', 'En ayunas'),
  beforeBreakfast('antes_desayuno', 'Antes del desayuno'),
  afterBreakfast('despues_desayuno', 'Después del desayuno'),
  beforeLunch('antes_almuerzo', 'Antes del almuerzo'),
  afterLunch('despues_almuerzo', 'Después del almuerzo'),
  beforeDinner('antes_cena', 'Antes de la cena'),
  afterDinner('despues_cena', 'Después de la cena'),
  beforeSleep('antes_dormir', 'Antes de dormir'),
  other('otra_medicion', 'Otra medición');

  final String code;
  final String label;

  const MeasurementType(this.code, this.label);

  static MeasurementType fromCode(String code) {
    return MeasurementType.values.firstWhere(
      (item) => item.code == code,
      orElse: () => MeasurementType.other,
    );
  }
}

enum GlucoseRangeStatus {
  belowRange('Por debajo del rango'),
  inRange('Dentro del rango'),
  aboveRange('Por encima del rango');

  final String label;
  const GlucoseRangeStatus(this.label);
}

class GlucoseRecord {
  final int? id;
  final double value;
  final String unit;
  final DateTime measuredAt;
  final MeasurementType measurementType;
  final String? notes;
  final DateTime createdAt;

  const GlucoseRecord({
    this.id,
    required this.value,
    required this.unit,
    required this.measuredAt,
    required this.measurementType,
    this.notes,
    required this.createdAt,
  });

  GlucoseRecord copyWith({
    int? id,
    double? value,
    String? unit,
    DateTime? measuredAt,
    MeasurementType? measurementType,
    String? notes,
    bool clearNotes = false,
    DateTime? createdAt,
  }) {
    return GlucoseRecord(
      id: id ?? this.id,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      measuredAt: measuredAt ?? this.measuredAt,
      measurementType: measurementType ?? this.measurementType,
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Devuelve el valor convertido a la unidad especificada.
  double valueIn(String targetUnit) {
    return GlucoseConverter.convert(
      value: value,
      fromUnit: unit,
      toUnit: targetUnit,
    );
  }

  /// Evalúa la medición respecto a los rangos personalizados del perfil (solo informativo).
  GlucoseRangeStatus evaluateAgainst(PatientProfile? profile) {
    final minVal = profile?.targetMinIn(unit) ??
        (unit == AppConstants.unitMgDl
            ? AppConstants.defaultMinMgDl
            : AppConstants.defaultMinMmolL);
    final maxVal = profile?.targetMaxIn(unit) ??
        (unit == AppConstants.unitMgDl
            ? AppConstants.defaultMaxMgDl
            : AppConstants.defaultMaxMmolL);

    if (value < minVal) return GlucoseRangeStatus.belowRange;
    if (value > maxVal) return GlucoseRangeStatus.aboveRange;
    return GlucoseRangeStatus.inRange;
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'value': value,
      'unit': unit,
      'measured_at': measuredAt.toIso8601String(),
      'measurement_type': measurementType.code,
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory GlucoseRecord.fromMap(Map<String, dynamic> map) {
    return GlucoseRecord(
      id: map['id'] as int?,
      value: (map['value'] as num).toDouble(),
      unit: (map['unit'] as String?) ?? AppConstants.unitMgDl,
      measuredAt: DateTime.parse(map['measured_at'] as String),
      measurementType: MeasurementType.fromCode(
        (map['measurement_type'] as String?) ?? 'otra_medicion',
      ),
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }
}
