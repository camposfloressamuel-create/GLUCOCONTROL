import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/gluco_provider.dart';
import '../services/statistics_service.dart';
import '../utils/app_theme.dart';
import '../utils/glucose_converter.dart';
import '../widgets/glucose_chart.dart';
import '../widgets/medical_disclaimer_banner.dart';
import 'blood_pressure_screen.dart';
import 'water_tracker_screen.dart';
import 'weight_bmi_screen.dart';

class HealthTrendsScreen extends StatelessWidget {
  const HealthTrendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GlucoProvider>();
    final profile = provider.profile;
    final weeklyGlucose = StatisticsService.filterByPeriod(
      provider.records,
      StatsPeriod.weekly,
    );
    final glucoseStats = StatisticsService.calculate(
      records: weeklyGlucose,
      profile: profile,
    );
    final latestBp = provider.latestBloodPressure;
    final latestWeight = provider.latestWeight;
    final waterGoal = provider.dailyWaterGoalMl;
    final waterToday = provider.todayWaterMl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen de tendencias'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // 1. Glucosa
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.water_drop_rounded,
                            color: AppColors.primaryGreen,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Glucosa (7 días)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        glucoseStats.totalCount == 0
                            ? '--'
                            : 'Prom: ${GlucoseConverter.formatValue(glucoseStats.average, glucoseStats.unit)} ${glucoseStats.unit}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GlucoseChart(
                    records: weeklyGlucose,
                    profile: profile,
                    height: 180,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2. Presión arterial
          _TrendSummaryTile(
            icon: Icons.favorite_rounded,
            iconColor: const Color(0xFFDC2626),
            iconBg: const Color(0xFFFEE2E2),
            title: 'Presión arterial y pulso',
            primaryValue: latestBp == null
                ? 'Sin registros'
                : '${latestBp.systolic}/${latestBp.diastolic} mmHg',
            secondaryText: latestBp == null
                ? 'Toca para registrar tu primera medición'
                : 'Pulso: ${latestBp.pulse} BPM • ${latestBp.category.label}',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const BloodPressureScreen(),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 3. Peso e IMC
          _TrendSummaryTile(
            icon: Icons.monitor_weight_rounded,
            iconColor: AppColors.secondaryBlue,
            iconBg: const Color(0xFFEAF3FC),
            title: 'Peso e IMC',
            primaryValue: latestWeight == null
                ? 'Sin registros'
                : '${latestWeight.weightKg.toStringAsFixed(1)} kg (IMC ${latestWeight.bmi.toStringAsFixed(1)})',
            secondaryText: latestWeight == null
                ? 'Toca para registrar peso y estatura'
                : latestWeight.category.label,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const WeightBmiScreen(),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 4. Hidratación diaria
          _TrendSummaryTile(
            icon: Icons.local_drink_rounded,
            iconColor: AppColors.primaryGreen,
            iconBg: AppColors.lightGreen,
            title: 'Hidratación de hoy',
            primaryValue: '$waterToday / $waterGoal ml',
            secondaryText:
                '${provider.todayWaterCups} vasos registrados hoy • Toca para sumar agua',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const WaterTrackerScreen(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const MedicalDisclaimerBanner(compact: true),
        ],
      ),
    );
  }
}

class _TrendSummaryTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String primaryValue;
  final String secondaryText;
  final VoidCallback onTap;

  const _TrendSummaryTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.primaryValue,
    required this.secondaryText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      primaryValue,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mainText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      secondaryText,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
