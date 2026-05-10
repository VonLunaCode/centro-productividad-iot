import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';
import '../../features/profiles/profiles_provider.dart';
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
  int? _selectedProfileId;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _stopwatch.isRunning) {
        setState(() => _timeDisplay = _formatDuration(_stopwatch.elapsed));
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(duration.inHours)}:${two(duration.inMinutes.remainder(60))}:${two(duration.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final wsData = ref.watch(websocketProvider);
    final alertState = ref.watch(alertProvider);

    if (!session.isActive) {
      return _buildStartSessionUI(session.isLoading);
    }

    if (!_stopwatch.isRunning) _stopwatch.start();

    final reading = wsData.value ?? {};

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            if (alertState.hasActiveAlert)
              _buildAlertBanner(alertState.primaryAlertMessage ?? 'Anomalía detectada'),

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
                  SensorCard(label: 'Postura', value: (reading['distance_mm'] ?? 0).toString(), unit: 'mm', icon: Icons.accessibility_new, isAlert: alertState.alerts['alert_posture'] ?? false),
                  SensorCard(label: 'Temperatura', value: (reading['temperature'] ?? 0.0).toStringAsFixed(1), unit: '°C', icon: Icons.thermostat, isAlert: alertState.alerts['alert_temp'] ?? false),
                  SensorCard(label: 'Humedad', value: (reading['humidity'] ?? 0).toString(), unit: '%', icon: Icons.water_drop, isAlert: alertState.alerts['alert_humidity'] ?? false),
                  SensorCard(label: 'Iluminación', value: (reading['lux'] ?? 0).toString(), unit: 'lux', icon: Icons.light_mode, isAlert: alertState.alerts['alert_light'] ?? false),
                  SensorCard(label: 'Ruido', value: (reading['noise_peak'] ?? 0).toString(), unit: 'dB', icon: Icons.volume_up, isAlert: alertState.alerts['alert_noise'] ?? false),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  if (alertState.hasActiveAlert)
                    PrimaryButton(
                      onPressed: () => ref.read(alertProvider.notifier).dismiss(),
                      child: const Text('Entendido'),
                    ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () async {
                      _stopwatch.stop();
                      _stopwatch.reset();
                      await ref.read(sessionProvider.notifier).stopSession();
                      if (mounted) context.pop();
                    },
                    child: const Text('Detener Sesión', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartSessionUI(bool isLoading) {
    final profilesState = ref.watch(profilesProvider);
    final profiles = profilesState.profiles;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () => context.pop(),
        ),
        title: const Text('Nueva Sesión', style: TextStyle(fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Elegí un perfil', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('El perfil define los umbrales de alerta para la sesión.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 32),

            if (profilesState.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (profiles.isEmpty)
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.person_off_outlined, color: Colors.white24, size: 48),
                    const SizedBox(height: 16),
                    const Text('No tenés perfiles creados.', style: TextStyle(color: Colors.white54)),
                    const SizedBox(height: 8),
                    TextButton(onPressed: () => context.pop(), child: const Text('Crear uno desde el dashboard')),
                  ],
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: profiles.length,
                  itemBuilder: (context, i) {
                    final p = profiles[i];
                    final selected = _selectedProfileId == p.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        opacity: selected ? 0.2 : 0.07,
                        padding: const EdgeInsets.all(16),
                        child: InkWell(
                          onTap: () => setState(() => _selectedProfileId = p.id),
                          child: Row(
                            children: [
                              Icon(
                                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: selected ? AppColors.primary : Colors.white38,
                              ),
                              const SizedBox(width: 16),
                              Expanded(child: Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 16))),
                              if (p.isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                  child: const Text('ACTIVO', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            if (profiles.isNotEmpty)
              PrimaryButton(
                onPressed: _selectedProfileId == null || isLoading
                    ? null
                    : () {
                        ref.read(sessionProvider.notifier).startSession(_selectedProfileId!).then((ok) {
                          if (!ok && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No se pudo iniciar la sesión. ¿El dispositivo está conectado?')),
                            );
                          }
                        });
                      },
                isLoading: isLoading,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow, size: 20),
                    SizedBox(width: 8),
                    Text('Iniciar Sesión'),
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
          Expanded(child: Text('ALERTA: $message', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
        ],
      ),
    );
  }
}
