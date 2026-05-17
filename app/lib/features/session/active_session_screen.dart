import 'dart:async';
import 'dart:math';
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

class _ActiveSessionScreenState extends ConsumerState<ActiveSessionScreen> with TickerProviderStateMixin {
  late Stopwatch _stopwatch;
  late Timer _timer;
  late AnimationController _skeletonAnim;
  late AnimationController _cardsEntranceAnim;
  late AnimationController _alertShakeAnim;
  late AnimationController _alertPulseAnim;
  bool _cardsAnimated = false;
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
    _skeletonAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _cardsEntranceAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _alertShakeAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _alertPulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _skeletonAnim.dispose();
    _cardsEntranceAnim.dispose();
    _alertShakeAnim.dispose();
    _alertPulseAnim.dispose();
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

    ref.listen(websocketProvider, (_, next) {
      if (!_cardsAnimated && next.hasValue) {
        _cardsAnimated = true;
        _cardsEntranceAnim.forward();
      }
    });

    ref.listen<AlertState>(alertProvider, (prev, next) {
      if (!(prev?.hasActiveAlert ?? false) && next.hasActiveAlert) {
        _alertShakeAnim.forward(from: 0);
        _alertPulseAnim.repeat(reverse: true);
      }
      if (!next.hasActiveAlert) {
        _alertPulseAnim.reset();
      }
    });

    if (!session.isActive) {
      return _buildStartSessionUI(session.isLoading);
    }

    if (session.isPaused) {
      if (_stopwatch.isRunning) _stopwatch.stop();
    } else {
      if (!_stopwatch.isRunning) _stopwatch.start();
    }

    final wsMsg = wsData.value ?? {};
    final reading = (wsMsg['sensors'] as Map<String, dynamic>?) ?? {};

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Column(
                    children: [
                      Text(
                        _timeDisplay,
                        style: TextStyle(
                          color: session.isPaused ? Colors.orange : Colors.white,
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
                              color: session.isPaused
                                  ? Colors.orange
                                  : wsData.hasValue
                                      ? AppColors.success
                                      : Colors.white24,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            session.isPaused
                                ? 'EN PAUSA'
                                : wsData.hasValue
                                    ? 'EN VIVO'
                                    : 'CONECTANDO...',
                            style: TextStyle(
                              color: session.isPaused ? Colors.orange : Colors.white38,
                              fontSize: 10,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Stack(
                    children: [
                      AnimatedOpacity(
                        opacity: session.isPaused ? 0.35 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: !wsData.hasValue
                            ? _buildSkeletonGrid()
                            : _buildSensorGrid(reading, alertState),
                      ),
                      if (session.isPaused)
                        const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.pause_circle_outline, color: Colors.white54, size: 52),
                              SizedBox(height: 8),
                              Text(
                                'Recolección pausada',
                                style: TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: 0.5),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: session.isPaused ? Colors.orange : Colors.white24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          ),
                          icon: Icon(
                            session.isPaused ? Icons.play_arrow : Icons.pause,
                            color: session.isPaused ? Colors.orange : Colors.white70,
                            size: 20,
                          ),
                          label: Text(
                            session.isPaused ? 'Retomar' : 'Pausar',
                            style: TextStyle(
                              color: session.isPaused ? Colors.orange : Colors.white70,
                            ),
                          ),
                          onPressed: () {
                            if (session.isPaused) {
                              ref.read(sessionProvider.notifier).resumeSession();
                            } else {
                              ref.read(sessionProvider.notifier).pauseSession();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.error),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          ),
                          icon: const Icon(Icons.stop_circle_outlined, color: AppColors.error, size: 20),
                          label: const Text('Detener', style: TextStyle(color: AppColors.error)),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: AppColors.background,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Text('¿Detener sesión?', style: TextStyle(color: Colors.white)),
                                content: const Text(
                                  'Se guardará el historial de esta sesión.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: const Text('Detener', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              _stopwatch.stop();
                              _stopwatch.reset();
                              await ref.read(sessionProvider.notifier).stopSession();
                              if (mounted) context.pop();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (alertState.hasActiveAlert && !session.isPaused)
            _buildAlertOverlay(context, alertState),
        ],
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

  Widget _buildSensorGrid(Map<String, dynamic> reading, AlertState alertState) {
    final sensors = [
      (label: 'Postura',     value: (reading['distance_mm'] as num? ?? 0).toDouble(), decimals: 0, unit: 'mm',  icon: Icons.accessibility_new, alertKey: 'alert_posture'),
      (label: 'Temperatura', value: (reading['temperature']  as num? ?? 0).toDouble(), decimals: 1, unit: '°C',  icon: Icons.thermostat,        alertKey: 'alert_temp'),
      (label: 'Humedad',     value: (reading['humidity']     as num? ?? 0).toDouble(), decimals: 0, unit: '%',   icon: Icons.water_drop,        alertKey: 'alert_humidity'),
      (label: 'Iluminación', value: (reading['lux']          as num? ?? 0).toDouble(), decimals: 0, unit: 'lux', icon: Icons.light_mode,        alertKey: 'alert_light'),
      (label: 'Ruido',       value: (reading['noise_peak']   as num? ?? 0).toDouble(), decimals: 0, unit: 'dB',  icon: Icons.volume_up,         alertKey: 'alert_noise'),
    ];

    return AnimatedBuilder(
      animation: _cardsEntranceAnim,
      builder: (_, __) {
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.4,
          ),
          itemCount: sensors.length,
          itemBuilder: (_, i) {
            final s = sensors[i];
            final start = i * 0.12;
            final interval = Interval(start, (start + 0.6).clamp(0.0, 1.0), curve: Curves.easeOutCubic);
            final anim = CurvedAnimation(parent: _cardsEntranceAnim, curve: interval);
            return FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(anim),
                child: SensorCard(
                  label: s.label,
                  value: s.value,
                  decimals: s.decimals,
                  unit: s.unit,
                  icon: s.icon,
                  isAlert: alertState.alerts[s.alertKey] ?? false,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSkeletonGrid() {
    return AnimatedBuilder(
      animation: _skeletonAnim,
      builder: (_, __) {
        final opacity = 0.04 + _skeletonAnim.value * 0.08;
        return GridView.count(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.4,
          children: List.generate(5, (_) => _buildSkeletonCard(opacity)),
        );
      },
    );
  }

  Widget _buildSkeletonCard(double opacity) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 14, height: 14, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 8),
              Container(width: 60, height: 10, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),
            ],
          ),
          const SizedBox(height: 12),
          Container(width: 56, height: 22, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),
        ],
      ),
    );
  }

  Widget _buildAlertOverlay(BuildContext context, AlertState alertState) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _alertShakeAnim,
        builder: (_, child) {
          final shake = sin(_alertShakeAnim.value * pi * 5) * 10 * (1 - _alertShakeAnim.value);
          return Transform.translate(offset: Offset(shake, 0), child: child!);
        },
        child: Container(
        color: Colors.black.withOpacity(0.85),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: Tween<double>(begin: 0.88, end: 1.08).animate(
                    CurvedAnimation(parent: _alertPulseAnim, curve: Curves.easeInOut),
                  ),
                  child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 52),
                ),
                ),
                const SizedBox(height: 24),
                Text(
                  'ALERTA · ${(alertState.primaryAlertMessage ?? '').toUpperCase()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  alertState.alertDetail ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  alertState.alertAdvice ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white60, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                    onPressed: () => ref.read(alertProvider.notifier).dismiss(),
                    child: const Text('Entendido', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                    onPressed: () => ref.read(alertProvider.notifier).snooze(),
                    child: const Text('Posponer 5 min', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
