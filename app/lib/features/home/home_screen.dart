import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_theme.dart';
import 'widgets/hub_card.dart';
import 'widgets/feature_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0x1A7B2FBE), Colors.transparent],
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header con Perfil y Notificaciones
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hola, Mateo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'SESIÓN LISTA PARA EMPEZAR',
                            style: TextStyle(
                              color: AppColors.primary.withOpacity(0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      _iconAction(Icons.notifications_outlined),
                      const SizedBox(width: 12),
                      _avatar('MA'),
                    ],
                  ),
                ),
              ),
              
              // Estado del Hub Principal
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: HubCard(
                    deviceName: 'HUB-A · Oficina',
                    isOnline: true,
                    sensorCount: 5,
                    signalStrength: -52,
                  ),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
              
              // Cuadrícula de Funcionalidades (Hub de Navegación)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.88,
                  children: [
                    FeatureCard(
                      title: 'Perfiles',
                      subtitle: '3 perfiles: Oficina, Reunión, Foco',
                      icon: Icons.person_search_outlined,
                      accentColor: AppColors.primary,
                      onTap: () => context.push(AppRoutes.profiles),
                    ),
                    FeatureCard(
                      title: 'Sesión Activa',
                      subtitle: 'Sin sesión. Inicia una desde un perfil',
                      icon: Icons.play_arrow_outlined,
                      accentColor: Colors.white24,
                      onTap: () => context.push(AppRoutes.session),
                    ),
                    FeatureCard(
                      title: 'Historial',
                      subtitle: '24 sesiones. Última: ayer 16:42',
                      icon: Icons.bar_chart_outlined,
                      accentColor: Colors.white24,
                      onTap: () => context.push(AppRoutes.history),
                    ),
                    FeatureCard(
                      title: 'Configuración',
                      subtitle: 'Permisos y cuenta. 2 pendientes',
                      icon: Icons.settings_outlined,
                      accentColor: Colors.white24,
                      onTap: () => context.push(AppRoutes.settings),
                    ),
                  ],
                ),
              ),
              
              // Accesos Rápidos Inferiores
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 40, 24, 8),
                  child: Text(
                    'ACCESO RÁPIDO',
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: _quickActionButton(
                          Icons.bluetooth_searching,
                          'Vincular dispositivo',
                          () => context.push(AppRoutes.onboarding),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _quickActionButton(
                          Icons.add,
                          'Nuevo perfil',
                          () => {}, // To implement
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconAction(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Icon(icon, color: Colors.white70, size: 20),
    );
  }

  Widget _avatar(String text) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryVariant],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _quickActionButton(IconData icon, String text, VoidCallback onTap) {
    return GlassCard(
      opacity: 0.05,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
