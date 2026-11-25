import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder_item.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  NotificationService._internal();

  static const String _glucoseChannelId = 'glucocontrol_mediciones';
  static const String _glucoseChannelName = 'Recordatorios de glucosa';
  static const String _glucoseChannelDesc =
      'Avisos locales para recordar la medición de glucosa.';

  static const String _appointmentChannelId = 'glucocontrol_citas';
  static const String _appointmentChannelName = 'Citas médicas';
  static const String _appointmentChannelDesc =
      'Avisos locales para recordar citas médicas programadas.';

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    _configureLocalTimeZone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _glucoseChannelId,
          _glucoseChannelName,
          description: _glucoseChannelDesc,
          importance: Importance.high,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _appointmentChannelId,
          _appointmentChannelName,
          description: _appointmentChannelDesc,
          importance: Importance.high,
        ),
      );
    }

    _initialized = true;
  }

  /// Ajusta tz.local a una zona horaria con el mismo desfase UTC que el dispositivo.
  void _configureLocalTimeZone() {
    final now = DateTime.now();
    final targetOffsetMs = now.timeZoneOffset.inMilliseconds;
    for (final location in tz.timeZoneDatabase.locations.values) {
      if (location.currentTimeZone.offset == targetOffsetMs) {
        tz.setLocalLocation(location);
        return;
      }
    }
  }

  /// Solicita permisos de notificación en Android 13+ y verifica alarmas exactas.
  Future<bool> requestPermissions() async {
    await initialize();
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return true;

    final granted = await androidPlugin.requestNotificationsPermission();
    return granted ?? true;
  }

  /// Determina si se pueden usar alarmas exactas o si se usa modo inexacto seguro.
  Future<AndroidScheduleMode> _resolveScheduleMode() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
    try {
      final canExact = await androidPlugin.canScheduleExactNotifications();
      if (canExact == true) {
        return AndroidScheduleMode.exactAllowWhileIdle;
      }
    } catch (_) {
      // Fallback seguro si el dispositivo no soporta la verificación.
    }
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  NotificationDetails _detailsFor(ReminderCategory category) {
    final isAppointment = category == ReminderCategory.medicalAppointment;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        isAppointment ? _appointmentChannelId : _glucoseChannelId,
        isAppointment ? _appointmentChannelName : _glucoseChannelName,
        channelDescription:
            isAppointment ? _appointmentChannelDesc : _glucoseChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );
  }

  /// Programa o cancela las notificaciones locales de un recordatorio.
  Future<void> syncReminder(ReminderItem reminder) async {
    if (reminder.id == null) return;
    await initialize();
    await cancelReminder(reminder.id!);

    if (!reminder.isEnabled) return;

    final scheduleMode = await _resolveScheduleMode();
    final details = _detailsFor(reminder.category);
    final body = reminder.description?.isNotEmpty == true
        ? reminder.description!
        : (reminder.category == ReminderCategory.medicalAppointment
            ? 'Recuerde su cita médica programada.'
            : 'Es momento de registrar su medición de glucosa en GlucoControl.');

    if (reminder.category == ReminderCategory.medicalAppointment &&
        reminder.appointmentDate != null) {
      final date = reminder.appointmentDate!;
      final scheduled = tz.TZDateTime(
        tz.local,
        date.year,
        date.month,
        date.day,
        reminder.hour,
        reminder.minute,
      );
      if (scheduled.isAfter(tz.TZDateTime.now(tz.local))) {
        await _plugin.zonedSchedule(
          _baseNotificationId(reminder.id!),
          reminder.title,
          body,
          scheduled,
          details,
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
      return;
    }

    if (reminder.frequency == ReminderFrequency.daily) {
      final scheduled = _nextInstanceOfTime(reminder.hour, reminder.minute);
      await _plugin.zonedSchedule(
        _baseNotificationId(reminder.id!),
        reminder.title,
        body,
        scheduled,
        details,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      return;
    }

    if (reminder.frequency == ReminderFrequency.weeklyDays) {
      for (final weekday in reminder.weekdays) {
        final scheduled = _nextInstanceOfWeekdayTime(
          weekday,
          reminder.hour,
          reminder.minute,
        );
        await _plugin.zonedSchedule(
          _baseNotificationId(reminder.id!) + weekday,
          reminder.title,
          body,
          scheduled,
          details,
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    }
  }

  /// Cancela todas las notificaciones asociadas a un recordatorio (base + 7 días).
  Future<void> cancelReminder(int reminderId) async {
    await initialize();
    final base = _baseNotificationId(reminderId);
    for (int offset = 0; offset <= 7; offset++) {
      await _plugin.cancel(base + offset);
    }
  }

  /// Reprograma todos los recordatorios activos (por ejemplo tras restaurar una copia de seguridad).
  Future<void> resyncAllReminders(List<ReminderItem> reminders) async {
    await initialize();
    await _plugin.cancelAll();
    for (final reminder in reminders) {
      if (reminder.isEnabled && reminder.id != null) {
        await syncReminder(reminder);
      }
    }
  }

  int _baseNotificationId(int reminderId) => reminderId * 10;

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOfWeekdayTime(int weekday, int hour, int minute) {
    var scheduled = _nextInstanceOfTime(hour, minute);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
