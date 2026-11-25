import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class MedicalDisclaimerBanner extends StatelessWidget {
  final bool compact;

  const MedicalDisclaimerBanner({super.key, this.compact = false});

  static void showFullDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(
              Icons.health_and_safety_outlined,
              color: AppColors.secondaryBlue,
              size: 28,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Responsabilidad médica',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            AppConstants.medicalDisclaimerFull,
            style: TextStyle(fontSize: 16, height: 1.45),
          ),
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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primaryGreen,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.medicalDisclaimerShort,
                  style: TextStyle(
                    fontSize: compact ? 13.5 : 14.5,
                    color: AppColors.mainText,
                    height: 1.35,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => showFullDialog(context),
                    child: const Text(
                      'Leer aviso médico completo',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryBlue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
