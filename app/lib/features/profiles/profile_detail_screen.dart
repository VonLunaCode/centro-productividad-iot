import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/router/app_router.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';
import 'models/profile.dart';
import 'profiles_provider.dart';

class ProfileDetailScreen extends ConsumerStatefulWidget {
  final Profile profile;

  const ProfileDetailScreen({super.key, required this.profile});

  @override
  ConsumerState<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends ConsumerState<ProfileDetailScreen> {
  bool _editing = false;
  bool _saving = false;

  final _sensors = [
    _SensorDef('posture',     'Postura',      'mm',   'distance_min', 'distance_max'),
    _SensorDef('temp',        'Temperatura',  '°C',   'temp_min',     'temp_max'),
    _SensorDef('humidity',    'Humedad',      '%',    'hum_min',      'hum_max'),
    _SensorDef('light',       'Iluminación',  'lux',  'lux_min',      'lux_max'),
    _SensorDef('noise',       'Ruido',        'dB',   'noise_peak_min','noise_peak_max'),
  ];

  late Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    final t = widget.profile.thresholds ?? {};
    for (final s in _sensors) {
      final entry = t[s.key] as Map<String, dynamic>?;
      _controllers['${s.key}_min'] = TextEditingController(
        text: entry?['min']?.toStringAsFixed(1) ?? '',
      );
      _controllers['${s.key}_max'] = TextEditingController(
        text: entry?['max']?.toStringAsFixed(1) ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final body = <String, dynamic>{};
    for (final s in _sensors) {
      final minText = _controllers['${s.key}_min']!.text.trim();
      final maxText = _controllers['${s.key}_max']!.text.trim();
      if (minText.isNotEmpty) body[s.backendMin] = double.tryParse(minText);
      if (maxText.isNotEmpty) body[s.backendMax] = double.tryParse(maxText);
    }
    body.removeWhere((_, v) => v == null);

    try {
      final response = await ApiClient.patch(
        Endpoints.updateThresholds(widget.profile.id),
        body,
      );
      if (response.statusCode == 200) {
        await ref.read(profilesProvider.notifier).fetchProfiles();
        if (mounted) setState(() => _editing = false);
      } else {
        _showError('Error al guardar (${response.statusCode})');
      }
    } catch (_) {
      _showError('Sin conexión');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(profilesProvider).profiles;
    final current = profiles.firstWhere(
      (p) => p.id == widget.profile.id,
      orElse: () => widget.profile,
    );
    final thresholds = current.thresholds ?? {};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(current.name),
        actions: [
          if (!_editing)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white70),
              onPressed: () => setState(() => _editing = true),
            )
          else
            TextButton(
              onPressed: () => setState(() => _editing = false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _editing ? 'Ajustar Umbrales' : 'Configuración de Umbrales',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _editing
                  ? 'Editá los valores mínimo y máximo para cada sensor.'
                  : 'Los umbrales se calculan automáticamente durante la calibración (media ± 2σ).',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 32),

            for (final s in _sensors)
              _editing
                  ? _editableItem(s)
                  : _readonlyItem(s.label, thresholds[s.key], s.unit),

            const SizedBox(height: 32),

            if (_editing)
              PrimaryButton(
                onPressed: _saving ? null : _save,
                isLoading: _saving,
                child: const Text('Guardar Cambios'),
              )
            else
              PrimaryButton(
                onPressed: () => context.push(AppRoutes.calibration, extra: current),
                child: const Text('Recalibrar Perfil'),
              ),

            const SizedBox(height: 16),

            if (current.isActive && !_editing)
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                onPressed: () => context.push(AppRoutes.session),
                child: const Text('Ir a Sesión Activa', style: TextStyle(color: AppColors.primary)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _readonlyItem(String label, dynamic value, String unit) {
    String displayValue = 'Sin datos';
    if (value != null) {
      final min = value['min']?.toStringAsFixed(1) ?? '?';
      final max = value['max']?.toStringAsFixed(1) ?? '?';
      displayValue = '$min - $max $unit';
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        opacity: 0.05,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text(displayValue, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _editableItem(_SensorDef s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        opacity: 0.05,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${s.label} (${s.unit})',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _numberField(_controllers['${s.key}_min']!, 'Mín')),
                const SizedBox(width: 12),
                Expanded(child: _numberField(_controllers['${s.key}_max']!, 'Máx')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white10,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _SensorDef {
  final String key;
  final String label;
  final String unit;
  final String backendMin;
  final String backendMax;

  const _SensorDef(this.key, this.label, this.unit, this.backendMin, this.backendMax);
}
