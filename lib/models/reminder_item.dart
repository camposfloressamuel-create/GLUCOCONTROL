enum ReminderCategory {
  glucoseCheck('glucosa', 'Medición de glucosa'),
  medicalAppointment('cita_medica', 'Cita médica');

  final String code;
  final String label;

  const ReminderCategory(this.code, this.label);

  static ReminderCategory fromCode(String code) {
    return ReminderCategory.values.firstWhere(
      (c) => c.code == code,
      orElse: () => ReminderCategory.glucoseCheck,
    );
  }
}

enum ReminderFrequency {
  daily('diaria', 'Todos los días'),
  weeklyDays('dias_semana', 'Días específicos'),
  oneTime('una_vez', 'Fecha única');

  final String code;
  final String label;

  const ReminderFrequency(this.code, this.label);

  static ReminderFrequency fromCode(String code) {
    return ReminderFrequency.values.firstWhere(
      (f) => f.code == code,
      orElse: () => ReminderFrequency.daily,
    );
  }
}

class ReminderItem {
  final int? id;
  final String title;
  final String? description;
  final ReminderCategory category;
  final ReminderFrequency frequency;
  final int hour;
  final int minute;

  /// Días de la semana (1 = Lunes ... 7 = Domingo), usados cuando frequency == weeklyDays.
  final List<int> weekdays;

  /// Fecha específica para recordatorios de cita médica (frequency == oneTime).
  final DateTime? appointmentDate;

  final bool isEnabled;
  final DateTime createdAt;

  const ReminderItem({
    this.id,
    required this.title,
    this.description,
    required this.category,
    required this.frequency,
    required this.hour,
    required this.minute,
    this.weekdays = const [],
    this.appointmentDate,
    this.isEnabled = true,
    required this.createdAt,
  });

  ReminderItem copyWith({
    int? id,
    String? title,
    String? description,
    bool clearDescription = false,
    ReminderCategory? category,
    ReminderFrequency? frequency,
    int? hour,
    int? minute,
    List<int>? weekdays,
    DateTime? appointmentDate,
    bool clearAppointmentDate = false,
    bool? isEnabled,
    DateTime? createdAt,
  }) {
    return ReminderItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description:
          clearDescription ? null : (description ?? this.description),
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      weekdays: weekdays ?? this.weekdays,
      appointmentDate: clearAppointmentDate
          ? null
          : (appointmentDate ?? this.appointmentDate),
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get formattedTime {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final mm = minute.toString().padLeft(2, '0');
    return '$displayHour:$mm $period';
  }

  String get scheduleSummary {
    if (category == ReminderCategory.medicalAppointment &&
        appointmentDate != null) {
      final d = appointmentDate!;
      final dd = d.day.toString().padLeft(2, '0');
      final mo = d.month.toString().padLeft(2, '0');
      return 'Cita el $dd/$mo/${d.year} a las $formattedTime';
    }
    if (frequency == ReminderFrequency.daily) {
      return 'Todos los días • $formattedTime';
    }
    if (frequency == ReminderFrequency.weeklyDays && weekdays.isNotEmpty) {
      const names = {
        1: 'Lun',
        2: 'Mar',
        3: 'Mié',
        4: 'Jue',
        5: 'Vie',
        6: 'Sáb',
        7: 'Dom',
      };
      final sorted = [...weekdays]..sort();
      final daysText = sorted.map((d) => names[d] ?? '').join(', ');
      return '$daysText • $formattedTime';
    }
    return formattedTime;
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title.trim(),
      'description': description?.trim().isEmpty == true
          ? null
          : description?.trim(),
      'category': category.code,
      'frequency': frequency.code,
      'hour': hour,
      'minute': minute,
      'weekdays': weekdays.join(','),
      'appointment_date': appointmentDate?.toIso8601String(),
      'is_enabled': isEnabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ReminderItem.fromMap(Map<String, dynamic> map) {
    final rawDays = (map['weekdays'] as String?) ?? '';
    final parsedDays = rawDays
        .split(',')
        .where((s) => s.trim().isNotEmpty)
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .where((d) => d >= 1 && d <= 7)
        .toList();

    return ReminderItem(
      id: map['id'] as int?,
      title: (map['title'] as String?) ?? '',
      description: map['description'] as String?,
      category: ReminderCategory.fromCode(
        (map['category'] as String?) ?? 'glucosa',
      ),
      frequency: ReminderFrequency.fromCode(
        (map['frequency'] as String?) ?? 'diaria',
      ),
      hour: (map['hour'] as num?)?.toInt() ?? 8,
      minute: (map['minute'] as num?)?.toInt() ?? 0,
      weekdays: parsedDays,
      appointmentDate: map['appointment_date'] != null
          ? DateTime.tryParse(map['appointment_date'] as String)
          : null,
      isEnabled: (map['is_enabled'] as num?)?.toInt() != 0,
      createdAt: map['created_at'] != null
          ? (DateTime.tryParse(map['created_at'] as String) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
