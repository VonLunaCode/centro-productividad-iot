import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_theme.dart';
import 'profiles_provider.dart';

class ProfileListScreen extends ConsumerWidget {
  const ProfileListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profilesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Perfiles de Monitoreo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () => _showCreateProfileDialog(context, ref),
          ),
        ],
      ),
      body: state.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text(state.error!, style: const TextStyle(color: AppColors.error)))
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: state.profiles.length,
                  itemBuilder: (context, index) {
                    final profile = state.profiles[index];
                    return _ProfileItem(profile: profile);
                  },
                ),
    );
  }

  void _showCreateProfileDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Nuevo Perfil'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nombre del perfil (ej: Oficina)'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final success = await ref.read(profilesProvider.notifier).createProfile(controller.text);
                if (success && context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }
}

class _ProfileItem extends ConsumerWidget {
  final dynamic profile;
  const _ProfileItem({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassCard(
        opacity: profile.isActive ? 0.15 : 0.05,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: profile.isActive ? AppColors.success : Colors.white10,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: profile.isActive ? FontWeight.bold : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    profile.isActive ? 'Perfil Activo' : 'Inactivo',
                    style: TextStyle(
                      color: profile.isActive ? AppColors.success : Colors.white24,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white38),
              onPressed: () {
                // Navegar al detalle (Phase 5.4)
                context.push(AppRoutes.profileDetail, extra: profile);
              },
            ),
            if (!profile.isActive)
              IconButton(
                icon: const Icon(Icons.check_circle_outline, color: AppColors.primary),
                onPressed: () => ref.read(profilesProvider.notifier).activateProfile(profile.id),
              ),
          ],
        ),
      ),
    );
  }
}
