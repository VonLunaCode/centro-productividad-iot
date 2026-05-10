import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';
import 'models/profile.dart';
import 'calibration_provider.dart';

class CalibrationScreen extends ConsumerStatefulWidget {
  final Profile profile;
  const CalibrationScreen({super.key, required this.profile});

  @override
  ConsumerState<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends ConsumerState<CalibrationScreen> {
  @override
  void dispose() {
    ref.read(calibrationProvider.notifier).reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calibrationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.status == CalibrationStatus.idle) ...[
                _buildIntro(),
              ] else if (state.status == CalibrationStatus.inProgress) ...[
                _buildProgress(state),
              ] else if (state.status == CalibrationStatus.success) ...[
                _buildSuccess(),
              ] else if (state.status == CalibrationStatus.error) ...[
                _buildError(state),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Column(
      children: [
        const Icon(Icons.accessibility_new, size: 80, color: AppColors.primary),
        const SizedBox(height: 32),
        const Text(
          'Iniciando Calibración',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'Mantén una postura correcta y quédate en silencio durante 30 segundos mientras el sistema captura tu entorno ideal.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        const SizedBox(height: 48),
        PrimaryButton(
          onPressed: () => ref.read(calibrationProvider.notifier).startCalibration(widget.profile.id),
          child: const Text('Comenzar'),
        ),
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Cancelar', style: TextStyle(color: Colors.white24)),
        ),
      ],
    );
  }

  Widget _buildProgress(CalibrationState state) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: CircularProgressIndicator(
                value: 1 - (state.secondsRemaining / 30),
                strokeWidth: 8,
                backgroundColor: Colors.white10,
                color: AppColors.primary,
              ),
            ),
            Text(
              '${state.secondsRemaining}s',
              style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 48),
        const Text(
          'Capturando datos...',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        const SizedBox(height: 8),
        const Text(
          'No te muevas',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        const Icon(Icons.check_circle, size: 80, color: AppColors.success),
        const SizedBox(height: 32),
        const Text(
          'Calibración Exitosa',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'Los umbrales han sido actualizados basándose en tu entorno actual.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 48),
        PrimaryButton(
          onPressed: () => context.pop(),
          child: const Text('Entendido'),
        ),
      ],
    );
  }

  Widget _buildError(CalibrationState state) {
    return Column(
      children: [
        const Icon(Icons.error_outline, size: 80, color: AppColors.error),
        const SizedBox(height: 32),
        const Text(
          'Error en la Calibración',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(state.error ?? 'Ocurrió un problema inesperado', style: const TextStyle(color: AppColors.error)),
        const SizedBox(height: 48),
        PrimaryButton(
          onPressed: () => ref.read(calibrationProvider.notifier).reset(),
          child: const Text('Reintentar'),
        ),
      ],
    );
  }
}
