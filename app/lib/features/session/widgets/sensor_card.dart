import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/app_colors.dart';

class SensorCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final bool isAlert;

  const SensorCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      opacity: isAlert ? 0.2 : 0.05,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: isAlert ? AppColors.error : Colors.white38),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isAlert ? AppColors.error : Colors.white70,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (isAlert)
                const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.error),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
