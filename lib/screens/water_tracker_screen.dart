import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/gluco_provider.dart';
import '../utils/app_theme.dart';
import '../utils/glucose_converter.dart';

class WaterTrackerScreen extends StatelessWidget {
  const WaterTrackerScreen({super.key});

  Future<void> _editGoal(BuildContext context, int currentGoal) async {
    final controller = TextEditingController(text: currentGoal.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Meta diaria de agua',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Meta en mililitros (ml)',
            hintText: 'Ej. 2000',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed != null && parsed >= 500 && parsed <= 6000) {
                Navigator.of(ctx).pop(parsed);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && context.mounted) {
      await context.read<GlucoProvider>().setDailyWaterGoalMl(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GlucoProvider>();
    final goal = provider.dailyWaterGoalMl;
    final todayMl = provider.todayWaterMl;
    final todayCups = provider.todayWaterCups;
    final todayList = provider.todayWaterRecords;
    final progress = goal > 0 ? (todayMl / goal).clamp(0.0, 1.0) : 0.0;
    final percent = (progress * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro diario de agua'),
        actions: [
          IconButton(
            tooltip: 'Cambiar meta diaria',
            icon: const Icon(
              Icons.edit_outlined,
              color: AppColors.secondaryBlue,
            ),
            onPressed: () => _editGoal(context, goal),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Tarjeta principal de hidratación
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.secondaryBlue, Color(0xFF1E5EA3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondaryBlue.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.water_drop_rounded,
                  color: AppColors.white,
                  size: 46,
                ),
                const SizedBox(height: 8),
                Text(
                  '$todayMl ml',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Meta diaria: $goal ml ($percent%)',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 14,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _WaterStat('Vasos hoy', '$todayCups'),
                      _WaterStat(
                        'Restante',
                        '${(goal - todayMl).clamp(0, goal)} ml',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Agregar agua rápidamente',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickWaterButton(
                  amountMl: 200,
                  label: 'Vaso\n200 ml',
                  onTap: () => provider.addWater(200),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickWaterButton(
                  amountMl: 250,
                  label: 'Vaso grande\n250 ml',
                  onTap: () => provider.addWater(250),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickWaterButton(
                  amountMl: 500,
                  label: 'Botella\n500 ml',
                  onTap: () => provider.addWater(500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          const Text(
            'Registros de hoy',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (todayList.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Aún no has registrado agua hoy. Pulsa uno de los botones azules para sumar tu primer vaso.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.5,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            )
          else
            ...todayList.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFEAF3FC),
                      child: Icon(
                        Icons.local_drink_rounded,
                        color: AppColors.secondaryBlue,
                      ),
                    ),
                    title: Text(
                      '+${item.amountMl} ml',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      GlucoseConverter.formatTime(item.loggedAt),
                      style: const TextStyle(fontSize: 14.5),
                    ),
                    trailing: IconButton(
                      tooltip: 'Eliminar',
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.belowRange,
                      ),
                      onPressed: item.id != null
                          ? () => provider.deleteWater(item.id!)
                          : null,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WaterStat extends StatelessWidget {
  final String label;
  final String value;

  const _WaterStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _QuickWaterButton extends StatelessWidget {
  final int amountMl;
  final String label;
  final VoidCallback onTap;

  const _QuickWaterButton({
    required this.amountMl,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEAF3FC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.secondaryBlue.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.add_circle_rounded,
                color: AppColors.secondaryBlue,
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryBlue,
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
