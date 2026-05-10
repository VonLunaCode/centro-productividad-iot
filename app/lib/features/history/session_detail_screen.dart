import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../shared/theme/app_colors.dart';
import 'models/session_history.dart';
import 'widgets/sensor_chart_card.dart';

class SessionDetailScreen extends StatelessWidget {
  final SessionHistory session;

  const SessionDetailScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
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
            _buildInfoRow('Inicio', session.startTime.toString().substring(0, 19)),
            _buildInfoRow('Fin', session.endTime?.toString().substring(0, 19) ?? '-'),
            _buildInfoRow('Duración Total', session.duration),
            const SizedBox(height: 32),
            
            const Text(
              'Análisis de Telemetría',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            SensorChartCard(
              label: 'Postura (mm)',
              color: AppColors.primary,
              spots: const [
                FlSpot(0, 450), FlSpot(1, 455), FlSpot(2, 448), FlSpot(3, 460), 
                FlSpot(4, 452), FlSpot(5, 450), FlSpot(6, 445),
              ],
            ),
            const SizedBox(height: 16),
            SensorChartCard(
              label: 'Ruido (dB)',
              color: Colors.orange,
              spots: const [
                FlSpot(0, 40), FlSpot(1, 42), FlSpot(2, 45), FlSpot(3, 50), 
                FlSpot(4, 48), FlSpot(5, 43), FlSpot(6, 41),
              ],
            ),
            const SizedBox(height: 16),
            SensorChartCard(
              label: 'Temperatura (°C)',
              color: Colors.redAccent,
              spots: const [
                FlSpot(0, 24), FlSpot(1, 24.2), FlSpot(2, 24.5), FlSpot(3, 24.4), 
                FlSpot(4, 24.3), FlSpot(5, 24.1), FlSpot(6, 24),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}
