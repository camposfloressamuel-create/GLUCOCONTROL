import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/reminder_item.dart';
import '../notifications/notification_service.dart';
import '../providers/gluco_provider.dart';
import '../utils/app_theme.dart';
import '../utils/glucose_converter.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  Future<void> _requestPermission() async {
    final granted = await NotificationService.instance.requestPermissions();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted
              ? 'Permiso de notificaciones activado correctamente.'
              : 'Active las notificaciones en Ajustes del teléfono para recibir los avisos.',
        ),
        backgroundColor:
            granted ? AppColors.primaryGreen : AppColors.aboveRange,
      ),
    );
  }

  Future<void> _openEditor({ReminderItem? existing}) async {
    await NotificationService.instance.requestPermissions();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ReminderEditorSheet(existing: existing),
    );
  }

  Future<void> _confirmDelete(ReminderItem reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Eliminar recordatorio',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '¿Desea eliminar el recordatorio "${reminder.title}"?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.belowRange,
            ),
            child: const Text('Eliminar', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );

    if (confirmed == true && reminder.id != null && mounted) {
      await context.read<GlucoProvider>().deleteReminder(reminder.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recordatorio eliminado.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GlucoProvider>();
    final reminders = provider.reminders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recordatorios'),
        actions: [
          IconButton(
            tooltip: 'Verificar permisos de notificaciones',
            icon: const Icon(
              Icons.notifications_active_outlined,
              color: AppColors.secondaryBlue,
            ),
            onPressed: _requestPermission,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add_alarm_rounded, size: 26),
        label: const Text(
          'Nuevo aviso',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: reminders.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.alarm_add_rounded,
                      size: 60,
                      color: AppColors.primaryGreen,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'No tiene recordatorios programados',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Cree avisos para medir su glucosa o recordar sus citas médicas. Funcionan sin conexión a internet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15.5,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: reminders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = reminders[index];
                final isAppointment =
                    item.category == ReminderCategory.medicalAppointment;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isAppointment
                                    ? const Color(0xFFEAF3FC)
                                    : AppColors.lightGreen,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isAppointment
                                    ? Icons.medical_services_outlined
                                    : Icons.alarm_rounded,
                                color: isAppointment
                                    ? AppColors.secondaryBlue
                                    : AppColors.primaryGreen,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item.scheduleSummary,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      color: AppColors.secondaryText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: item.isEnabled,
                              activeThumbColor: AppColors.primaryGreen,
                              onChanged: (val) =>
                                  provider.toggleReminder(item, val),
                            ),
                          ],
                        ),
                        if (item.description != null &&
                            item.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            item.description!,
                            style: const TextStyle(
                              fontSize: 14.5,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _openEditor(existing: item),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Editar'),
                            ),
                            TextButton.icon(
                              onPressed: () => _confirmDelete(item),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: AppColors.belowRange,
                              ),
                              label: const Text(
                                'Eliminar',
                                style: TextStyle(color: AppColors.belowRange),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _ReminderEditorSheet extends StatefulWidget {
  final ReminderItem? existing;

  const _ReminderEditorSheet({this.existing});

  @override
  State<_ReminderEditorSheet> createState() => _ReminderEditorSheetState();
}

class _ReminderEditorSheetState extends State<_ReminderEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  ReminderCategory _category = ReminderCategory.glucoseCheck;
  ReminderFrequency _frequency = ReminderFrequency.daily;
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  final Set<int> _weekdays = {1, 2, 3, 4, 5};
  DateTime _appointmentDate = DateTime.now().add(const Duration(days: 1));
  bool _saving = false;

  static const Map<int, String> _dayLabels = {
    1: 'L',
    2: 'M',
    3: 'X',
    4: 'J',
    5: 'V',
    6: 'S',
    7: 'D',
  };

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleController.text = e.title;
      _descController.text = e.description ?? '';
      _category = e.category;
      _frequency = e.frequency;
      _time = TimeOfDay(hour: e.hour, minute: e.minute);
      if (e.weekdays.isNotEmpty) {
        _weekdays
          ..clear()
          ..addAll(e.weekdays);
      }
      if (e.appointmentDate != null) {
        _appointmentDate = e.appointmentDate!;
      }
    } else {
      _titleController.text = 'Medir glucosa en ayunas';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickAppointmentDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _appointmentDate.isBefore(now) ? now : _appointmentDate,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      locale: const Locale('es'),
    );
    if (picked != null) setState(() => _appointmentDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == ReminderCategory.glucoseCheck &&
        _frequency == ReminderFrequency.weeklyDays &&
        _weekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione al menos un día de la semana.'),
          backgroundColor: AppColors.belowRange,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final isAppointment = _category == ReminderCategory.medicalAppointment;
      final item = ReminderItem(
        id: widget.existing?.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        category: _category,
        frequency: isAppointment ? ReminderFrequency.oneTime : _frequency,
        hour: _time.hour,
        minute: _time.minute,
        weekdays: isAppointment ? const [] : (_weekdays.toList()..sort()),
        appointmentDate: isAppointment ? _appointmentDate : null,
        isEnabled: widget.existing?.isEnabled ?? true,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
      );

      final provider = context.read<GlucoProvider>();
      if (widget.existing == null) {
        await provider.addReminder(item);
      } else {
        await provider.updateReminder(item);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recordatorio guardado correctamente.'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al programar el recordatorio: $e'),
          backgroundColor: AppColors.belowRange,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existing == null
                    ? 'Nuevo recordatorio'
                    : 'Editar recordatorio',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<ReminderCategory>(
                segments: const [
                  ButtonSegment(
                    value: ReminderCategory.glucoseCheck,
                    label: Text('Medir glucosa'),
                    icon: Icon(Icons.water_drop_outlined),
                  ),
                  ButtonSegment(
                    value: ReminderCategory.medicalAppointment,
                    label: Text('Cita médica'),
                    icon: Icon(Icons.medical_services_outlined),
                  ),
                ],
                selected: {_category},
                onSelectionChanged: (sel) {
                  if (sel.isNotEmpty) {
                    setState(() {
                      _category = sel.first;
                      if (_category == ReminderCategory.medicalAppointment &&
                          _titleController.text == 'Medir glucosa en ayunas') {
                        _titleController.text = 'Cita de control médico';
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Título del recordatorio *',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingrese un título' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nota adicional (opcional)',
                  hintText: 'Ej. Llevar cuaderno o informe PDF',
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.borderGray),
                ),
                leading: const Icon(
                  Icons.access_time_rounded,
                  color: AppColors.primaryGreen,
                ),
                title: const Text('Hora del aviso'),
                trailing: Text(
                  _time.format(context),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreen,
                  ),
                ),
                onTap: _pickTime,
              ),
              const SizedBox(height: 12),
              if (_category == ReminderCategory.medicalAppointment)
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.borderGray),
                  ),
                  leading: const Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.secondaryBlue,
                  ),
                  title: const Text('Fecha de la cita'),
                  trailing: Text(
                    GlucoseConverter.formatDate(_appointmentDate),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondaryBlue,
                    ),
                  ),
                  onTap: _pickAppointmentDate,
                )
              else ...[
                SegmentedButton<ReminderFrequency>(
                  segments: const [
                    ButtonSegment(
                      value: ReminderFrequency.daily,
                      label: Text('Todos los días'),
                    ),
                    ButtonSegment(
                      value: ReminderFrequency.weeklyDays,
                      label: Text('Días específicos'),
                    ),
                  ],
                  selected: {
                    _frequency == ReminderFrequency.oneTime
                        ? ReminderFrequency.daily
                        : _frequency,
                  },
                  onSelectionChanged: (sel) {
                    if (sel.isNotEmpty) {
                      setState(() => _frequency = sel.first);
                    }
                  },
                ),
                if (_frequency == ReminderFrequency.weeklyDays) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _dayLabels.entries.map((entry) {
                      final active = _weekdays.contains(entry.key);
                      return FilterChip(
                        label: Text(
                          entry.value,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: active ? AppColors.white : AppColors.mainText,
                          ),
                        ),
                        selected: active,
                        selectedColor: AppColors.primaryGreen,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _weekdays.add(entry.key);
                            } else {
                              _weekdays.remove(entry.key);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Guardando...' : 'Guardar recordatorio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
