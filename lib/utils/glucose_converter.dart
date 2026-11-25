import 'package:intl/intl.dart';
import 'constants.dart';

class GlucoseConverter {
  /// Convierte un valor de glucosa entre mg/dL y mmol/L.
  static double convert({
    required double value,
    required String fromUnit,
    required String toUnit,
  }) {
    if (fromUnit == toUnit) return value;
    if (fromUnit == AppConstants.unitMgDl && toUnit == AppConstants.unitMmolL) {
      return double.parse(
        (value / AppConstants.conversionFactor).toStringAsFixed(1),
      );
    }
    if (fromUnit == AppConstants.unitMmolL && toUnit == AppConstants.unitMgDl) {
      return (value * AppConstants.conversionFactor).roundToDouble();
    }
    return value;
  }

  /// Formatea un valor de glucosa para visualización legible.
  static String formatValue(double value, String unit) {
    if (unit == AppConstants.unitMmolL) {
      return value.toStringAsFixed(1);
    }
    return value.round().toString();
  }

  /// Valida si un valor ingresado en texto es numérico, positivo y está dentro de los límites seguros.
  static String? validateInput(String? rawValue, String unit) {
    if (rawValue == null || rawValue.trim().isEmpty) {
      return 'Por favor ingrese el valor de glucosa.';
    }
    final normalized = rawValue.trim().replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null) {
      return 'Ingrese un número válido (ejemplo: ${unit == AppConstants.unitMgDl ? '110' : '6.1'}).';
    }
    if (parsed <= 0) {
      return 'El valor debe ser mayor que cero.';
    }
    if (unit == AppConstants.unitMgDl) {
      if (parsed < AppConstants.minInputMgDl ||
          parsed > AppConstants.maxInputMgDl) {
        return 'Ingrese un valor entre ${AppConstants.minInputMgDl.toInt()} y ${AppConstants.maxInputMgDl.toInt()} mg/dL.';
      }
    } else {
      if (parsed < AppConstants.minInputMmolL ||
          parsed > AppConstants.maxInputMmolL) {
        return 'Ingrese un valor entre ${AppConstants.minInputMmolL} y ${AppConstants.maxInputMmolL} mmol/L.';
      }
    }
    return null;
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'es').format(date);
  }

  static String formatLongDate(DateTime date) {
    return DateFormat("d 'de' MMMM 'de' y", 'es').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a', 'es').format(date);
  }

  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} • ${formatTime(date)}';
  }

  static String greetingForHour(int hour) {
    if (hour < 12) return 'Buenos días';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }
}
