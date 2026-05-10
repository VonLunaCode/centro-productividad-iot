import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';
import 'models/profile.dart';
import 'profiles_provider.dart';

class ProfileDetailScreen extends ConsumerWidget {
  final Profile profile;
  
  const ProfileDetailScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thresholds = profile.thresholds ?? {};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(profile.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuración de Umbrales',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Los umbrales se calculan automáticamente durante la calibración (media ± 2σ).',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 32),
            
            _thresholdItem('Postura (mm)', thresholds['posture']),
            _thresholdItem('Temperatura (°C)', thresholds['temp']),
            _thresholdItem('Humedad (%)', thresholds['humidity']),
            _thresholdItem('Iluminación (lux)', thresholds['light']),
            _thresholdItem('Ruido (dB)', thresholds['noise']),
            
            const SizedBox(height: 40),
            
            PrimaryButton(
              onPressed: () => context.push(AppRoutes.calibration, extra: profile),
              child: const Text('Recalibrar Perfil'),
            ),
            
            const SizedBox(height: 16),
            
            if (profile.isActive)
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

  Widget _thresholdItem(String label, dynamic value) {
    String displayValue = 'Sin datos';
    if (value != null) {
      final min = value['min']?.toStringAsFixed(1) ?? '0';
      final max = value['max']?.toStringAsFixed(1) ?? '0';
      displayValue = '$min - $max';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassCard(
        opacity: 0.05,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text(
              displayValue,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
