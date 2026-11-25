class AppConstants {
  static const String appName = 'GlucoControl';
  static const String appSlogan = 'Tu glucosa bajo control, todos los días.';
  static const String appVersion = '1.0.0';

  // Unidades soportadas
  static const String unitMgDl = 'mg/dL';
  static const String unitMmolL = 'mmol/L';

  // Límites de entrada seguros (para evitar errores de digitación)
  static const double minInputMgDl = 20.0;
  static const double maxInputMgDl = 600.0;
  static const double minInputMmolL = 1.1;
  static const double maxInputMmolL = 33.3;

  // Rangos de referencia iniciales sugeridos (totalmente editables según indicación médica)
  static const double defaultMinMgDl = 70.0;
  static const double defaultMaxMgDl = 140.0;
  static const double defaultMinMmolL = 3.9;
  static const double defaultMaxMmolL = 7.8;

  // Factor estándar de conversión mg/dL <-> mmol/L
  static const double conversionFactor = 18.0182;

  // Versión de esquema de copia de seguridad JSON
  static const int backupSchemaVersion = 1;

  // Textos de responsabilidad médica
  static const String medicalDisclaimerShort =
      'GlucoControl es una herramienta personal de registro y organización. '
      'No sustituye la consulta médica ni ofrece diagnósticos o ajustes de tratamiento.';

  static const String medicalDisclaimerFull =
      'Aviso importante sobre responsabilidad médica:\n\n'
      '• GlucoControl es exclusivamente una herramienta de apoyo para registrar, '
      'organizar y consultar mediciones de glucosa.\n'
      '• Esta aplicación NO diagnostica diabetes ni otras condiciones médicas.\n'
      '• Esta aplicación NO recomienda dosis de insulina ni cambios en medicamentos.\n'
      '• Esta aplicación NO sustituye la valoración ni el seguimiento de su médico o '
      'profesional de la salud.\n'
      '• Configure siempre los rangos de referencia indicados por su médico.\n'
      '• Ante cualquier valor fuera de su rango habitual o cualquier síntoma, siga '
      'las indicaciones de su profesional sanitario o acuda a un servicio de salud.';

  static const String outOfRangeNotice =
      'Esta medición se encuentra fuera del rango de referencia configurado. '
      'Este aviso es únicamente informativo: siga siempre las indicaciones de su '
      'médico o profesional sanitario.';
}
