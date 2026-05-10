import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';
import 'alert_provider.dart';
import '../../core/websocket/websocket_provider.dart';
import 'session_provider.dart';
import 'widgets/sensor_card.dart';

class ActiveSessionScreen extends ConsumerStatefulWidget {
  const ActiveSessionScreen({super.key});

  @override
  ConsumerState<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends ConsumerState<ActiveSessionScreen> {
  late Stopwatch _stopwatch;
  late Timer _timer;
  String _timeDisplay = "00:00:00";

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _timeDisplay = _formatDuration(_stopwatch.elapsed);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final wsData = ref.watch(websocketProvider);
    final alertState = ref.watch(alertProvider);
    
    final reading = wsData.value ?? {};

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Banner de Alerta Dinámico
            if (alertState.hasActiveAlert)
              _buildAlertBanner(alertState.primaryAlertMessage ?? 'Anomalía detectada'),

            // Timer Header
            Padding(
              padding: EdgeInsets.symmetric(vertical: alertState.hasActiveAlert ? 20.0 : 40.0),
              child: Column(
                children: [
                  Text(
                    _timeDisplay,
                    style: TextStyle(
                      color: alertState.hasActiveAlert ? AppColors.error : Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Courier',
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: wsData.hasValue ? AppColors.success : Colors.white24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        wsData.hasValue ? 'EN VIVO' : 'CONECTANDO...',
                        style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.4,
                children: [
                  SensorCard(
                    label: 'Postura',
                    value: (reading['distance_mm'] ?? 0).toString(),
                    unit: 'mm',
                    icon: Icons.accessibility_new,
                    isAlert: alertState.alerts['alert_posture'] ?? false,
                  ),
                  SensorCard(
                    label: 'Temperatura',
                    value: (reading['temperature'] ?? 0.0).toStringAsFixed(1),
                    unit: '°C',
                    icon: Icons.thermostat,
                    isAlert: alertState.alerts['alert_temp'] ?? false,
                  ),
                  SensorCard(
                    label: 'Humedad',
                    value: (reading['humidity'] ?? 0).toString(),
                    unit: '%',
                    icon: Icons.water_drop,
                    isAlert: alertState.alerts['alert_humidity'] ?? false,
                  ),
                  SensorCard(
                    label: 'Iluminación',
                    value: (reading['lux'] ?? 0).toString(),
                    unit: 'lux',
                    icon: Icons.light_mode,
                    isAlert: alertState.alerts['alert_light'] ?? false,
                  ),
                  SensorCard(
                    label: 'Ruido',
                    value: (reading['noise_peak'] ?? 0).toString(),
                    unit: 'dB',
                    icon: Icons.volume_up,
                    isAlert: alertState.alerts['alert_noise'] ?? false,
                  ),
                ],
              ),
            ),
            
            // Botones de Acción Inferiores
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  PrimaryButton(
                    onPressed: () => ref.read(alertProvider.notifier).dismiss(),
                    child: const Text('Entendido'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () async {
                      await ref.read(sessionProvider.notifier).stopSession();
                      if (mounted) context.pop();
                    },
                    child: const Text(
                      'Detener Sesión',
                      style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      color: AppColors.error.withOpacity(0.9),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'ALERTA: $message',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
