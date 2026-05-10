import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/app_colors.dart';

class HubCard extends StatelessWidget {
  final String deviceName;
  final bool isOnline;
  final int sensorCount;
  final int signalStrength;

  const HubCard({
    super.key,
    required this.deviceName,
    required this.isOnline,
    required this.sensorCount,
    required this.signalStrength,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      opacity: 0.1,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.devices_other, color: Colors.white70, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deviceName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOnline ? AppColors.success : AppColors.error,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOnline ? 'ONLINE' : 'OFFLINE',
                          style: TextStyle(
                            color: isOnline ? AppColors.success : AppColors.error,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoItem(Icons.sensors, '$sensorCount sensores'),
              _infoItem(Icons.wifi, 'WiFi'),
              Text(
                '${signalStrength}dBm',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white38),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
