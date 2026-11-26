import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/gluco_provider.dart';
import '../services/backup_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/glucose_converter.dart';
import '../widgets/medical_disclaimer_banner.dart';
import 'profile_setup_screen.dart';
import 'reports_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;

  Future<void> _exportBackup() async {
    setState(() => _busy = true);
    try {
      final provider = context.read<GlucoProvider>();
      final file = await BackupService.exportToLocalFile(
        profile: provider.profile,
        records: provider.records,
        reminders: provider.reminders,
        bloodPressureRecords: provider.bloodPressureRecords,
        weightRecords: provider.weightRecords,
        waterRecords: provider.waterRecords,
      );
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Copia de seguridad GlucoControl',
        text: 'Respaldo local de datos de GlucoControl.',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Copia guardada localmente: ${file.path.split('/').last}',
          ),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo exportar la copia de seguridad: $e'),
          backgroundColor: AppColors.belowRange,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importBackup() async {
    setState(() => _busy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final payload = BackupService.parseAndValidateBackup(content);

      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Confirmar restauración',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Se encontró una copia de seguridad válida:\n\n'
            '• Paciente: ${payload.profile?.fullName ?? "Sin nombre"}\n'
            '• Mediciones de glucosa: ${payload.records.length}\n'
            '• Presión arterial: ${payload.bloodPressureRecords.length}\n'
            '• Peso e IMC: ${payload.weightRecords.length}\n'
            '• Recordatorios: ${payload.reminders.length}\n\n'
            'Al continuar, se sobrescribirá la información actual en este teléfono. ¿Desea restaurar esta copia?',
            style: const TextStyle(fontSize: 16, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
              ),
              child: const Text('Restaurar', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        await context.read<GlucoProvider>().restoreFromBackup(payload);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Copia de seguridad restaurada correctamente.'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }
    } on BackupValidationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.belowRange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo importar el archivo: $e'),
          backgroundColor: AppColors.belowRange,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GlucoProvider>();
    final profile = provider.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil y opciones'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.lightGreen,
                child: Icon(
                  Icons.person_rounded,
                  color: AppColors.primaryGreen,
                  size: 30,
                ),
              ),
              title: Text(
                profile?.fullName.isNotEmpty == true
                    ? profile!.fullName
                    : 'Configurar perfil',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: profile == null
                  ? const Text('Toque para ingresar los datos del paciente')
                  : Text(
                      'Unidad: ${profile.preferredUnit} • Rango: ${GlucoseConverter.formatValue(profile.targetMin, profile.preferredUnit)}-${GlucoseConverter.formatValue(profile.targetMax, profile.preferredUnit)}',
                      style: const TextStyle(fontSize: 14.5),
                    ),
              trailing: const Icon(Icons.chevron_right_rounded, size: 28),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ProfileSetupScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: const Icon(
                Icons.picture_as_pdf_rounded,
                color: AppColors.secondaryBlue,
                size: 30,
              ),
              title: const Text(
                'Informes en PDF',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Descargar, compartir o imprimir para el médico',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ReportsScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.backup_outlined,
                        color: AppColors.primaryGreen,
                        size: 28,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Copias de seguridad locales',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Exporte sus datos a un archivo JSON local o restaure una copia guardada anteriormente. Ningún dato se sube a servidores externos.',
                    style: TextStyle(
                      fontSize: 14.5,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: _busy ? null : _exportBackup,
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('Exportar copia de seguridad (JSON)'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _importBackup,
                    icon: const Icon(Icons.restore_rounded),
                    label: const Text('Importar y restaurar copia'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.health_and_safety_outlined,
                    color: AppColors.secondaryBlue,
                    size: 28,
                  ),
                  title: const Text(
                    'Advertencia de responsabilidad médica',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Lea el alcance informativo de la aplicación',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => MedicalDisclaimerBanner.showFullDialog(context),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.primaryGreen,
                    size: 28,
                  ),
                  title: Text(
                    'Privacidad 100% local',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Sin cuentas, sin anuncios, sin suscripciones y sin conexión a internet.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              '${AppConstants.appName} v${AppConstants.appVersion}\n${AppConstants.appSlogan}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
