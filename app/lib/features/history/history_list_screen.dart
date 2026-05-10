import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_theme.dart';
import 'history_provider.dart';

class HistoryListScreen extends ConsumerWidget {
  const HistoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Historial de Sesiones', style: TextStyle(fontSize: 18)),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.sessions.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: state.sessions.length,
                  itemBuilder: (context, index) {
                    final session = state.sessions[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: GlassCard(
                        opacity: 0.05,
                        padding: const EdgeInsets.all(16),
                        child: InkWell(
                          onTap: () => context.push(AppRoutes.sessionDetail, extra: session),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.history, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sesión #${session.id}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${session.startTime.day}/${session.startTime.month} · ${session.duration}',
                                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.white12),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 64, color: Colors.white12),
          SizedBox(height: 16),
          Text('No hay sesiones registradas', style: TextStyle(color: Colors.white24)),
        ],
      ),
    );
  }
}
