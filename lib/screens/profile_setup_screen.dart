import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/patient_profile.dart';
import '../providers/gluco_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/glucose_converter.dart';
import 'home_shell.dart';

class ProfileSetupScreen extends StatefulWidget {
  final bool isInitial;

  const ProfileSetupScreen({super.key, this.isInitial = false});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _minController = TextEditingController();
  final _maxController = TextEditingController();

  String _unit = AppConstants.unitMgDl;
  DateTime? _birthDate;
  DateTime _trackingStartDate = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = context.read<GlucoProvider>().profile;
    if (existing != null) {
      _nameController.text = existing.fullName;
      _unit = existing.preferredUnit;
      _birthDate = existing.birthDate;
      _trackingStartDate = existing.trackingStartDate;
      _minController.text = GlucoseConverter.formatValue(
        existing.targetMin,
        existing.preferredUnit,
      );
      _maxController.text = GlucoseConverter.formatValue(
        existing.targetMax,
        existing.preferredUnit,
      );
    } else {
      _minController.text = AppConstants.defaultMinMgDl.round().toString();
      _maxController.text = AppConstants.defaultMaxMgDl.round().toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _onUnitChanged(String newUnit) {
    if (newUnit == _unit) return;
    final currentMin = double.tryParse(_minController.text.replaceAll(',', '.'));
    final currentMax = double.tryParse(_maxController.text.replaceAll(',', '.'));

    setState(() {
      if (currentMin != null && currentMin > 0) {
        final convertedMin = GlucoseConverter.convert(
          value: currentMin,
          fromUnit: _unit,
          toUnit: newUnit,
        );
        _minController.text = GlucoseConverter.formatValue(
          convertedMin,
          newUnit,
        );
      } else {
        _minController.text = newUnit == AppConstants.unitMgDl
            ? AppConstants.defaultMinMgDl.round().toString()
            : AppConstants.defaultMinMmolL.toStringAsFixed(1);
      }

      if (currentMax != null && currentMax > 0) {
        final convertedMax = GlucoseConverter.convert(
          value: currentMax,
          fromUnit: _unit,
          toUnit: newUnit,
        );
        _maxController.text = GlucoseConverter.formatValue(
          convertedMax,
          newUnit,
        );
      } else {
        _maxController.text = newUnit == AppConstants.unitMgDl
            ? AppConstants.defaultMaxMgDl.round().toString()
            : AppConstants.defaultMaxMmolL.toStringAsFixed(1);
      }
      _unit = newUnit;
    });
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 55, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
      locale: const Locale('es'),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _pickTrackingStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _trackingStartDate,
      firstDate: DateTime(2000),
      lastDate: now,
      locale: const Locale('es'),
    );
    if (picked != null) {
      setState(() => _trackingStartDate = picked);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final minVal = double.parse(_minController.text.trim().replaceAll(',', '.'));
    final maxVal = double.parse(_maxController.text.trim().replaceAll(',', '.'));

    if (minVal >= maxVal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El valor mínimo del rango debe ser menor que el valor máximo.',
          ),
          backgroundColor: AppColors.belowRange,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final provider = context.read<GlucoProvider>();
      final profile = PatientProfile(
        id: provider.profile?.id,
        fullName: _nameController.text.trim(),
        birthDate: _birthDate,
        preferredUnit: _unit,
        targetMin: minVal,
        targetMax: maxVal,
        trackingStartDate: _trackingStartDate,
        updatedAt: DateTime.now(),
      );
      await provider.saveProfile(profile);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil guardado correctamente.'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );

      if (widget.isInitial) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const HomeShell()),
          (_) => false,
        );
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo guardar el perfil: $e'),
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
          widget.isInitial ? 'Configurar perfil' : 'Perfil del paciente',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Datos básicos del paciente',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainText,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Solo pedimos la información necesaria para personalizar sus registros y reportes. Todo se guarda únicamente en este teléfono.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  labelText: 'Nombre completo *',
                  hintText: 'Ej. María Gómez',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingrese el nombre del paciente.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  leading: const Icon(
                    Icons.cake_outlined,
                    color: AppColors.secondaryBlue,
                    size: 28,
                  ),
                  title: const Text(
                    'Fecha de nacimiento (opcional)',
                    style: TextStyle(fontSize: 15, color: AppColors.secondaryText),
                  ),
                  subtitle: Text(
                    _birthDate != null
                        ? GlucoseConverter.formatLongDate(_birthDate!)
                        : 'Sin registrar',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainText,
                    ),
                  ),
                  trailing: _birthDate != null
                      ? IconButton(
                          tooltip: 'Quitar fecha',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(() => _birthDate = null),
                        )
                      : const Icon(Icons.calendar_today_rounded),
                  onTap: _pickBirthDate,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  leading: const Icon(
                    Icons.event_available_rounded,
                    color: AppColors.primaryGreen,
                    size: 28,
                  ),
                  title: const Text(
                    'Fecha de inicio del seguimiento',
                    style: TextStyle(fontSize: 15, color: AppColors.secondaryText),
                  ),
                  subtitle: Text(
                    GlucoseConverter.formatLongDate(_trackingStartDate),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainText,
                    ),
                  ),
                  trailing: const Icon(Icons.calendar_today_rounded),
                  onTap: _pickTrackingStartDate,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Unidad de glucosa preferida',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainText,
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: AppConstants.unitMgDl,
                    label: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'mg/dL',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  ButtonSegment<String>(
                    value: AppConstants.unitMmolL,
                    label: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'mmol/L',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
                selected: {_unit},
                onSelectionChanged: (selection) {
                  if (selection.isNotEmpty) {
                    _onUnitChanged(selection.first);
                  }
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Rango de referencia indicado por su médico',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainText,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Estos valores sirven únicamente para resaltar visualmente sus mediciones en las tarjetas y gráficas.',
                style: TextStyle(
                  fontSize: 14.5,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Mínimo ($_unit)',
                      ),
                      validator: (v) => GlucoseConverter.validateInput(v, _unit),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextFormField(
                      controller: _maxController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Máximo ($_unit)',
                      ),
                      validator: (v) => GlucoseConverter.validateInput(v, _unit),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _saving ? null : _saveProfile,
                icon: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 24),
                label: Text(
                  widget.isInitial
                      ? 'Guardar y continuar'
                      : 'Guardar cambios',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
