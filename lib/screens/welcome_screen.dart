import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/app_logo.dart';
import '../widgets/medical_disclaimer_banner.dart';
import 'profile_setup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              const AppLogo(size: 112),
              const SizedBox(height: 22),
              const Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryGreen,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                AppConstants.appSlogan,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              _FeatureTile(
                icon: Icons.edit_note_rounded,
                title: 'Registro sencillo y rápido',
                subtitle:
                    'Guarde sus mediciones de glucosa en segundos con botones grandes y claros.',
              ),
              const SizedBox(height: 14),
              _FeatureTile(
                icon: Icons.show_chart_rounded,
                title: 'Historial, gráficas e informes PDF',
                subtitle:
                    'Consulte su evolución y genere reportes en PDF para llevar a su consulta médica.',
              ),
              const SizedBox(height: 14),
              _FeatureTile(
                icon: Icons.notifications_active_outlined,
                title: 'Recordatorios sin internet',
                subtitle:
                    'Programe avisos diarios y citas médicas. Sus datos siempre permanecen en su teléfono.',
              ),
              const SizedBox(height: 22),
              const MedicalDisclaimerBanner(compact: true),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfileSetupScreen(isInitial: true),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 24),
                label: const Text('Comenzar'),
              ),
              const SizedBox(height: 12),
              const Text(
                '100% gratuita • Sin anuncios • 100% sin conexión',
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryGreen, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.secondaryText,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
