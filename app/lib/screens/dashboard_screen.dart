import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../providers/profiles_provider.dart';
import '../providers/sensor_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/metric_card.dart';
import '../widgets/profile_chip.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _calibrating = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    // Initialize WS connection
    ref.read(wsServiceProvider);
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  Color _bgColor(bool posture, bool lowLight) {
    if (_calibrating) return const Color(0xFF0A0A0A); // silenciar alertas
    if (posture) return const Color(0xFF3B0A0A);
    if (lowLight) return const Color(0xFF3B2A00);
    return const Color(0xFF0A0A0A);
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(profilesProvider);
    final sensorAsync = ref.watch(sensorStreamProvider);
    final activeId = ref.watch(activeProfileIdProvider);
    final alerts = ref.watch(alertStateProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        color: _bgColor(alerts.posture, alerts.lowLight),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ───────────────────────────────────────────
                Text(
                  'Centro de Productividad',
                  style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _statusText(alerts),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 24),

                // ── Profile Chips ─────────────────────────────────────
                profilesAsync.when(
                  loading: () => const SizedBox(height: 40),
                  error: (e, _) => Text('Error: $e',
                      style: const TextStyle(color: Colors.red)),
                  data: (profiles) {
                    // On first load, set active ID from server
                    if (activeId == null) {
                      final serverActive =
                          profiles.where((p) => p.isActive).firstOrNull;
                      if (serverActive != null) {
                        Future.microtask(() => ref
                            .read(activeProfileIdProvider.notifier)
                            .state = serverActive.id);
                      }
                    }
                    final currentId = activeId ??
                        profiles.where((p) => p.isActive).firstOrNull?.id;

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: profiles
                            .map((p) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ProfileChip(
                                    profile: p,
                                    isSelected: p.id == currentId,
                                    onTap: () => ref
                                        .read(activateProfileProvider)(p.id),
                                  ),
                                ))
                            .toList(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // ── Main Distance Card ────────────────────────────────
                GlassCard(
                  child: sensorAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: Colors.white30)),
                    error: (e, _) => Text('Sin conexión',
                        style: GoogleFonts.inter(color: Colors.white54)),
                    data: (reading) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${reading.sensors.distanceMm} mm',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Distancia al sensor',
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Metrics Grid ──────────────────────────────────────
                sensorAsync.when(
                  loading: () => const SizedBox(height: 100),
                  error: (_, __) => const SizedBox(height: 100),
                  data: (reading) => Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          label: 'Temperatura',
                          value: reading.sensors.temperatureC
                              .toStringAsFixed(1),
                          unit: '°C',
                          icon: Icons.thermostat_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MetricCard(
                          label: 'Humedad',
                          value: reading.sensors.humidityPct
                              .toStringAsFixed(0),
                          unit: '%',
                          icon: Icons.water_drop_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MetricCard(
                          label: 'Luz',
                          value: reading.sensors.lightRaw.toString(),
                          unit: 'raw',
                          icon: Icons.light_mode_outlined,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Calibrate Button ──────────────────────────────────
                profilesAsync.whenData((profiles) {
                  final currentId = ref.watch(activeProfileIdProvider) ??
                      profiles.where((p) => p.isActive).firstOrNull?.id;
                  return currentId;
                }).valueOrNull != null
                    ? SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _calibrating
                              ? null
                              : () async {
                                  final currentId =
                                      ref.read(activeProfileIdProvider);
                                  if (currentId == null) return;
                                  setState(() => _calibrating = true);
                                  try {
                                    await ref.read(
                                        calibrateProfileProvider)(currentId);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                        content:
                                            Text('✅ Postura calibrada'),
                                        backgroundColor: Colors.green,
                                      ));
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: Colors.red,
                                      ));
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => _calibrating = false);
                                    }
                                  }
                                },
                          icon: _calibrating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.black54),
                                )
                              : const Icon(Icons.my_location),
                          label: Text(
                            _calibrating
                                ? 'Calibrando...'
                                : 'Calibrar Postura',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _statusText(({bool posture, bool lowLight}) alerts) {
    if (_calibrating) return '📡 Calibrando...';
    if (alerts.posture) return '⚠ Corregí la postura';
    if (alerts.lowLight) return '💡 Poca luz';
    return '✓ Postura óptima';
  }
}
