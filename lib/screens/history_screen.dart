import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/glucose_record.dart';
import '../providers/gluco_provider.dart';
import '../utils/app_theme.dart';
import '../utils/glucose_converter.dart';
import '../widgets/glucose_record_card.dart';
import 'add_glucose_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchController = TextEditingController();
  DateTimeRange? _dateRange;
  MeasurementType? _selectedType;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: _dateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
      locale: const Locale('es'),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _dateRange = null;
      _selectedType = null;
    });
  }

  Future<void> _confirmDelete(GlucoseRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Eliminar medición',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '¿Seguro que desea eliminar el registro de ${GlucoseConverter.formatValue(record.value, record.unit)} ${record.unit} del ${GlucoseConverter.formatDateTime(record.measuredAt)}?\n\nEsta acción no se puede deshacer.',
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
              backgroundColor: AppColors.belowRange,
            ),
            child: const Text('Eliminar', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );

    if (confirmed == true && record.id != null && mounted) {
      await context.read<GlucoProvider>().deleteRecord(record.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medición eliminada.'),
          backgroundColor: AppColors.mainText,
        ),
      );
    }
  }

  List<GlucoseRecord> _applyFilters(List<GlucoseRecord> allRecords) {
    final q = _searchController.text.trim().toLowerCase();
    return allRecords.where((r) {
      if (_selectedType != null && r.measurementType != _selectedType) {
        return false;
      }
      if (_dateRange != null) {
        final start = DateTime(
          _dateRange!.start.year,
          _dateRange!.start.month,
          _dateRange!.start.day,
        );
        final end = DateTime(
          _dateRange!.end.year,
          _dateRange!.end.month,
          _dateRange!.end.day,
          23,
          59,
          59,
          999,
        );
        if (r.measuredAt.isBefore(start) || r.measuredAt.isAfter(end)) {
          return false;
        }
      }
      if (q.isNotEmpty) {
        final notes = (r.notes ?? '').toLowerCase();
        final typeLabel = r.measurementType.label.toLowerCase();
        final valText = GlucoseConverter.formatValue(r.value, r.unit);
        final dateText = GlucoseConverter.formatDate(r.measuredAt);
        if (!notes.contains(q) &&
            !typeLabel.contains(q) &&
            !valText.contains(q) &&
            !dateText.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GlucoProvider>();
    final filtered = _applyFilters(provider.records);
    final hasFilters = _dateRange != null ||
        _selectedType != null ||
        _searchController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de mediciones'),
        actions: [
          if (hasFilters)
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear_all_rounded),
              label: const Text('Limpiar'),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nota, tipo o valor...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onPressed: _pickDateRange,
                        icon: const Icon(Icons.date_range_rounded, size: 20),
                        label: Text(
                          _dateRange == null
                              ? 'Filtrar fechas'
                              : '${GlucoseConverter.formatDate(_dateRange!.start)} - ${GlucoseConverter.formatDate(_dateRange!.end)}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<MeasurementType?>(
                        initialValue: _selectedType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        hint: const Text(
                          'Todos los tipos',
                          style: TextStyle(fontSize: 14),
                        ),
                        items: [
                          const DropdownMenuItem<MeasurementType?>(
                            value: null,
                            child: Text(
                              'Todos los tipos',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          ...MeasurementType.values.map(
                            (t) => DropdownMenuItem<MeasurementType?>(
                              value: t,
                              child: Text(
                                t.label,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedType = value);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.history_toggle_off_rounded,
                            size: 56,
                            color: AppColors.secondaryText,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            hasFilters
                                ? 'No hay mediciones que coincidan con los filtros.'
                                : 'Aún no tiene mediciones guardadas.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final record = filtered[index];
                      return GlucoseRecordCard(
                        record: record,
                        profile: provider.profile,
                        onEdit: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  AddGlucoseScreen(existingRecord: record),
                            ),
                          );
                        },
                        onDelete: () => _confirmDelete(record),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
