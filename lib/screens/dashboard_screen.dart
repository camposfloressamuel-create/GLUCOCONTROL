import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/glucose_record.dart';
import '../models/patient_profile.dart';
import '../providers/gluco_provider.dart';
import '../services/statistics_service.dart';
import '../utils/app_theme.dart';
import '../utils/glucose_converter.dart';
import '../widgets/app_logo.dart';
import '../widgets/glucose_chart.dart';
import '../widgets/glucose_record_card.dart';
import '../widgets/medical_disclaimer_banner.dart';
import 'reports_screen.dart';

class DashboardScreen extends StatelessWidget {
  final ValueChanged<int> onNavigateTab;
  final VoidCallback onAddGlucose;

  const DashboardScreen({
    super.key,
    required this.onNavigateTab,
    required this.onAddGlucose,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GlucoProvider>();
    final profile = provider.profile;
    final latest = provider.latestRecord;
    final todayCount = provider.todayRecordsCount;
    final weeklyRecords = StatisticsService.filterByPeriod(
      provider.records,
      StatsPeriod.weekly,
    );
    final recentRecords = provider.records.take(3).toList();
    final greeting = GlucoseConverter.greetingForHour(DateTime.now().hour);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            AppLogo(size: 36),
            SizedBox(width: 10),
            Text('GlucoControl'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Generar informe PDF',
            icon: const Icon(
              Icons.picture_as_pdf_outlined,
              color: AppColors.secondaryBlue,
              size: 28,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ReportsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 96),
        children: [
          Text(
            '$greeting,',
            style: const TextStyle(
              fontSize: 17,
              color: AppColors.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            profile?.fullName.isNotEmpty == true
                ? profile!.fullName
                : 'Paciente',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.mainText,
            ),
          ),
          const SizedBox(height: 18),
          _LatestMeasurementHeroCard(
            latest: latest,
            profile: profile,
            todayCount: todayCount,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.add_circle_outline_rounded,
                  label: 'Registrar\nglucosa',
                  color: AppColors.primaryGreen,
                  bgColor: AppColors.lightGreen,
                  onTap: onAddGlucose,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'Informe\nPDF',
                  color: AppColors.secondaryBlue,
                  bgColor: const Color(0xFFEAF3FC),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ReportsScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.history_rounded,
                  label: 'Historial',
                  color: AppColors.mainText,
                  bgColor: AppColors.white,
                  onTap: () => onNavigateTab(1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.show_chart_rounded,
                  label: 'Gráficas',
                  color: AppColors.mainText,
                  bgColor: AppColors.white,
                  onTap: () => onNavigateTab(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.notifications_active_outlined,
                  label: 'Alertas',
                  color: AppColors.mainText,
                  bgColor: AppColors.white,
                  onTap: () => onNavigateTab(3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Evolución (últimos 7 días)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mainText,
                        ),
                      ),
                      TextButton(
                        onPressed: () => onNavigateTab(2),
                        child: const Text(
                          'Ver más',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  GlucoseChart(
                    records: weeklyRecords,
                    profile: profile,
                    height: 210,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Últimas mediciones',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainText,
                ),
              ),
              if (provider.records.isNotEmpty)
                TextButton(
                  onPressed: () => onNavigateTab(1),
                  child: const Text(
                    'Ver todas',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (recentRecords.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(22),
                child: Column(
                  children: [
                    Icon(
                      Icons.water_drop_outlined,
                      size: 46,
                      color: AppColors.primaryGreen,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Todavía no hay mediciones registradas.',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Pulse el botón "Registrar glucosa" para guardar su primera medición.',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.secondaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...recentRecords.map(
              (rec) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlucoseRecordCard(
                  record: rec,
                  profile: profile,
                ),
              ),
            ),
          const SizedBox(height: 12),
          const MedicalDisclaimerBanner(),
        ],
      ),
    );
  }
}

class _LatestMeasurementHeroCard extends StatelessWidget {
  final GlucoseRecord? latest;
  final PatientProfile? profile;
  final int todayCount;

  const _LatestMeasurementHeroCard({
    required this.latest,
    required this.profile,
    required this.todayCount,
  });

  @override
  Widget build(BuildContext context) {
    final status = latest?.evaluateAgainst(profile);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryGreen, Color(0xFF118757)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Última medición',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightGreen,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Hoy: $todayCount ${todayCount == 1 ? 'registro' : 'registros'}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (latest == null)
            const Text(
              'Sin registros aún',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  GlucoseConverter.formatValue(latest!.value, latest!.unit),
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  latest!.unit,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${latest!.measurementType.label} • ${GlucoseConverter.formatDateTime(latest!.measuredAt)}',
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (status != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: status == GlucoseRangeStatus.inRange
                        ? AppColors.inRange
                        : (status == GlucoseRangeStatus.aboveRange
                            ? AppColors.aboveRange
                            : AppColors.belowRange),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGray, width: 0.9),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
