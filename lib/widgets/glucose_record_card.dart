import 'package:flutter/material.dart';

import '../models/glucose_record.dart';
import '../models/patient_profile.dart';
import '../utils/app_theme.dart';
import '../utils/glucose_converter.dart';

class GlucoseRecordCard extends StatelessWidget {
  final GlucoseRecord record;
  final PatientProfile? profile;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const GlucoseRecordCard({
    super.key,
    required this.record,
    required this.profile,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final status = record.evaluateAgainst(profile);
    final Color statusColor;
    final Color statusBg;
    final IconData statusIcon;

    switch (status) {
      case GlucoseRangeStatus.inRange:
        statusColor = AppColors.inRange;
        statusBg = AppColors.inRangeBg;
        statusIcon = Icons.check_circle_rounded;
        break;
      case GlucoseRangeStatus.aboveRange:
        statusColor = AppColors.aboveRange;
        statusBg = AppColors.aboveRangeBg;
        statusIcon = Icons.arrow_upward_rounded;
        break;
      case GlucoseRangeStatus.belowRange:
        statusColor = AppColors.belowRange;
        statusBg = AppColors.belowRangeBg;
        statusIcon = Icons.arrow_downward_rounded;
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        GlucoseConverter.formatValue(record.value, record.unit),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        record.unit,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.measurementType.label,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mainText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        GlucoseConverter.formatDateTime(record.measuredAt),
                        style: const TextStyle(
                          fontSize: 14.5,
                          color: AppColors.secondaryText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(statusIcon, size: 16, color: statusColor),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              status.label,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onEdit != null || onDelete != null)
                  Column(
                    children: [
                      if (onEdit != null)
                        IconButton(
                          tooltip: 'Editar medición',
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: AppColors.secondaryBlue,
                          ),
                          onPressed: onEdit,
                        ),
                      if (onDelete != null)
                        IconButton(
                          tooltip: 'Eliminar medición',
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.belowRange,
                          ),
                          onPressed: onDelete,
                        ),
                    ],
                  ),
              ],
            ),
            if (record.notes != null && record.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.notes_rounded,
                      size: 18,
                      color: AppColors.secondaryText,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        record.notes!.trim(),
                        style: const TextStyle(
                          fontSize: 14.5,
                          color: AppColors.mainText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
