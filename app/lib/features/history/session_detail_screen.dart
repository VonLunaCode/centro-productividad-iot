import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_theme.dart';
import 'models/session_history.dart';

class SessionDetailScreen extends StatelessWidget {
  final SessionHistory session;

  const SessionDetailScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final date = session.startedAt;
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Sesión #${session.id}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassCard(
              opacity: 0.05,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _infoRow('Perfil', session.profileName ?? 'Sin perfil'),
                  const SizedBox(height: 10),
                  _infoRow('Fecha', dateStr),
                  const SizedBox(height: 10),
                  _infoRow('Duración', session.durationFormatted),
                  const SizedBox(height: 10),
                  _infoRow('Lecturas totales', '${session.totalReadings}'),
                ],
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              'Resumen de Alertas',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              '% del tiempo con cada alerta activa',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 20),

            _alertBar('Postura', session.postureAlertPct, Icons.accessibility_new, AppColors.error),
            _alertBar('Temperatura', session.tempAlertPct, Icons.thermostat, Colors.orange),
            _alertBar('Ruido', session.noiseAlertPct, Icons.volume_up, Colors.purple),
            _alertBar('Iluminación', session.lightAlertPct, Icons.light_mode, Colors.yellow),
            _alertBar('Humedad', session.humidityAlertPct, Icons.water_drop, Colors.blue),

            const SizedBox(height: 32),

            GlassCard(
              opacity: 0.05,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.insights, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Alerta dominante', style: TextStyle(color: Colors.white38, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          session.dominantAlert,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 14)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _alertBar(String label, double pct, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const Spacer(),
              Text(
                '${pct.toStringAsFixed(1)}%',
                style: TextStyle(color: pct > 20 ? color : Colors.white38, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(
                pct > 30 ? color : color.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
