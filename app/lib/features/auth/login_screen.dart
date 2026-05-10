import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/glass_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_userController.text.isEmpty || _passController.text.isEmpty) {
      return;
    }
    
    final success = await ref.read(authProvider.notifier).login(
      _userController.text,
      _passController.text,
    );
    
    if (success && mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [Color(0x337B2FBE), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Logo decorativo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.1),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.gps_fixed, size: 48, color: AppColors.primary),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Centro de Productividad',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const Text(
                  'IoT',
                  style: TextStyle(
                    fontSize: 28,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'Serif',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'cuida tu espacio, cuida tu trabajo',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 60),
                GlassTextField(
                  controller: _userController,
                  label: 'Usuario',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 24),
                GlassTextField(
                  controller: _passController,
                  label: 'Contraseña',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  errorText: authState.error,
                ),
                const SizedBox(height: 48),
                PrimaryButton(
                  onPressed: _handleLogin,
                  isLoading: authState.isLoading,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Iniciar sesión'),
                      SizedBox(width: 12),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.push('/register'),
                  child: const Text.rich(
                    TextSpan(
                      text: '¿No tenés cuenta? ',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                      children: [
                        TextSpan(
                          text: 'Registrate',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
