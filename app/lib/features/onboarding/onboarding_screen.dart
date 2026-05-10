import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  StreamSubscription? scanSubscription;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    super.dispose();
  }

  void _startScan() async {
    setState(() => isScanning = true);
    
    // Iniciar escaneo de 15 segundos
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    
    scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          // Filtrar por dispositivos que empiecen con HUB (opcional)
          scanResults = results;
        });
      }
    });

    await Future.delayed(const Duration(seconds: 15));
    if (mounted) setState(() => isScanning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Configurar Dispositivo', style: TextStyle(fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const Icon(Icons.bluetooth_searching, size: 80, color: AppColors.primary),
            const SizedBox(height: 32),
            const Text(
              'Buscando tu Hub...',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Asegúrate de que tu hardware esté encendido y cerca de tu teléfono.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
            const SizedBox(height: 48),
            Expanded(
              child: scanResults.isEmpty
                  ? _buildLoader()
                  : ListView.builder(
                      itemCount: scanResults.length,
                      itemBuilder: (context, index) {
                        final result = scanResults[index];
                        final name = result.device.platformName.isEmpty 
                            ? 'Dispositivo Desconocido' 
                            : result.device.platformName;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: GlassCard(
                            opacity: 0.05,
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Icon(Icons.router_outlined, color: AppColors.primary),
                                const SizedBox(width: 16),
                                Expanded(child: Text(name, style: const TextStyle(color: Colors.white))),
                                TextButton(
                                  onPressed: () => _pairDevice(result.device),
                                  child: const Text('Vincular'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 24),
            if (!isScanning)
              PrimaryButton(
                onPressed: _startScan,
                child: const Text('Buscar de nuevo'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoader() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  void _pairDevice(BluetoothDevice device) async {
    // Aquí iría la lógica de vinculación real
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('¡Vinculado!'),
        content: Text('Se ha establecido conexión con ${device.platformName}.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/');
            },
            child: const Text('Empezar'),
          ),
        ],
      ),
    );
  }
}
