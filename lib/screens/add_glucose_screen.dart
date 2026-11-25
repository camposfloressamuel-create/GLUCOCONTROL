import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/glucose_record.dart';
import '../providers/gluco_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/glucose_converter.dart';

class AddGlucoseScreen extends StatefulWidget {
  final GlucoseRecord? existingRecord;

  const AddGlucoseScreen({super.key, this.existingRecord});

  @override
  State<AddGlucoseScreen> createState() => _AddGlucoseScreenState();
}

class _AddGlucoseScreenState extends State<AddGlucoseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();

  late String _unit;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  MeasurementType _selectedType = MeasurementType.fasting;
  bool _saving = false;

  bool get _isEditing => widget.existingRecord != null;

  @override
  void initState() {
    super.initState();
    final provider = context.read<GlucoProvider>();
    final rec = widget.existingRecord;
    if (rec != null) {
      _unit = rec.unit;
      _valueController.text = GlucoseConverter.formatValue(rec.value, rec.unit);
      _selectedDate = DateTime(
        rec.measuredAt.year,
        rec.measuredAt.month,
        rec.measuredAt.day,
      );
      _selectedTime = TimeOfDay(
        hour: rec.measuredAt.hour,
        minute: rec.measuredAt.minute,
      );
      _selectedType = rec.measurementType;
      _notesController.text = rec.notes ?? '';
    } else {
      final now = DateTime.now();
      _unit = provider.preferredUnit;
      _selectedDate = DateTime(now.year, now.month, now.day);
      _selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  DateTime get _combinedDateTime => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: now,
      locale: const Locale('es'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    final parsed = double.parse(
      _valueController.text.trim().replaceAll(',', '.'),
    );

    setState(() => _saving = true);
    try {
      final provider = context.read<GlucoProvider>();
      final record = GlucoseRecord(
        id: widget.existingRecord?.id,
        value: parsed,
        unit: _unit,
        measuredAt: _combinedDateTime,
        measurementType: _selectedType,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: widget.existingRecord?.createdAt ?? DateTime.now(),
      );

      if (_isEditing) {
        await provider.updateRecord(record);
      } else {
        await provider.addRecord(record);
      }

      if (!mounted) return;
      final status = record.evaluateAgainst(provider.profile);

      if (status != GlucoseRangeStatus.inRange) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: status == GlucoseRangeStatus.aboveRange
                      ? AppColors.aboveRange
                      : AppColors.belowRange,
                  size: 28,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Medición guardada',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            content: Text(
              'Valor registrado: ${GlucoseConverter.formatValue(record.value, record.unit)} ${record.unit} (${status.label}).\n\n${AppConstants.outOfRangeNotice}',
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                ),
                child: const Text('Entendido', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Medición actualizada correctamente.'
                  : 'Medición guardada correctamente.',
            ),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar la medición: $e'),
          backgroundColor: AppColors.belowRange,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Editar medición' : 'Registrar glucosa',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Valor de glucosa y unidad
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Valor de glucosa',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _valueController,
                        autofocus: !_isEditing,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryGreen,
                        ),
                        decoration: InputDecoration(
                          hintText: _unit == AppConstants.unitMgDl ? '110' : '6.1',
                          suffixText: _unit,
                          suffixStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        validator: (v) => GlucoseConverter.validateInput(v, _unit),
                      ),
                      const SizedBox(height: 14),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment<String>(
                            value: AppConstants.unitMgDl,
                            label: Text(
                              'mg/dL',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          ButtonSegment<String>(
                            value: AppConstants.unitMmolL,
                            label: Text(
                              'mmol/L',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        selected: {_unit},
                        onSelectionChanged: (sel) {
                          if (sel.isNotEmpty) {
                            setState(() => _unit = sel.first);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Fecha y hora
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(18),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 18,
                                    color: AppColors.secondaryBlue,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Fecha',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                GlucoseConverter.formatDate(_combinedDateTime),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      child: InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(18),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 18,
                                    color: AppColors.primaryGreen,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Hora',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                GlucoseConverter.formatTime(_combinedDateTime),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tipo de medición (9 opciones exactas)
              const Text(
                'Tipo de medición',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainText,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MeasurementType.values.map((type) {
                  final selected = _selectedType == type;
                  return ChoiceChip(
                    label: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Text(
                        type.label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? AppColors.white
                              : AppColors.mainText,
                        ),
                      ),
                    ),
                    selected: selected,
                    selectedColor: AppColors.primaryGreen,
                    backgroundColor: AppColors.white,
                    side: BorderSide(
                      color: selected
                          ? AppColors.primaryGreen
                          : AppColors.borderGray,
                    ),
                    onSelected: (_) => setState(() => _selectedType = type),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Observaciones opcionales
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Observaciones (opcional)',
                  hintText: 'Ej. Caminata de 20 minutos, comida ligera...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 26),

              // Botón obligatorio GUARDAR MEDICIÓN
              ElevatedButton.icon(
                onPressed: _saving ? null : _saveRecord,
                icon: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(Icons.save_rounded, size: 24),
                label: Text(
                  _isEditing ? 'ACTUALIZAR MEDICIÓN' : 'GUARDAR MEDICIÓN',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
