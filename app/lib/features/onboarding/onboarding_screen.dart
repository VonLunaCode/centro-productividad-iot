import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/glass_text_field.dart';

const _serviceUuid    = '12345678-1234-1234-1234-123456789abc';
const _ssidUuid       = '12345678-1234-1234-1234-123456789001';
const _passUuid       = '12345678-1234-1234-1234-123456789002';
const _statusUuid     = '12345678-1234-1234-1234-123456789003';
const _deviceName     = 'CentroProductividad';

enum _Phase { scanning, connecting, credentials, provisioning, success, error }

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  _Phase _phase = _Phase.scanning;
  BluetoothDevice? _device;
  String _statusMessage = '';
  StreamSubscription? _scanSub;
  StreamSubscription? _statusSub;
  final _ssidController = TextEditingController();
  final _passController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _statusSub?.cancel();
    _device?.disconnect();
    _ssidController.dispose();
    _passController.dispose();
    super.dispose();
  }

  List<ScanResult> _scanResults = [];
  List<WiFiAccessPoint> _wifiNetworks = [];
  String? _selectedSsid;
  bool _loadingWifi = false;

  void _startScan() async {
    setState(() {
      _phase = _Phase.scanning;
      _device = null;
      _scanResults = [];
    });

    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 20),
      androidUsesFineLocation: false,
    );

    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      if (_phase != _Phase.scanning || !mounted) return;

      // Auto-conectar si encontramos el dispositivo por nombre
      final match = results.where((r) =>
        r.device.platformName == _deviceName ||
        r.advertisementData.advName == _deviceName,
      );
      if (match.isNotEmpty) {
        FlutterBluePlus.stopScan();
        _connectTo(match.first.device);
        return;
      }

      // Si no, mostrar todos para selección manual
      final filtered = results
          .where((r) => r.device.platformName.isNotEmpty || r.advertisementData.advName.isNotEmpty)
          .toList();
      if (filtered.isNotEmpty) setState(() => _scanResults = filtered);
    });
  }

  Future<void> _scanWifi() async {
    setState(() => _loadingWifi = true);
    await Permission.location.request();
    await WiFiScan.instance.startScan();
    final results = await WiFiScan.instance.getScannedResults();
    if (mounted) {
      setState(() {
        final seen = <String>{};
        _wifiNetworks = results
            .where((ap) => ap.ssid.isNotEmpty && seen.add(ap.ssid))
            .toList()
          ..sort((a, b) => b.level.compareTo(a.level));
        _loadingWifi = false;
      });
    }
  }

  Future<void> _connectTo(BluetoothDevice device) async {
    setState(() {
      _phase = _Phase.connecting;
      _device = device;
      _statusMessage = 'Conectando...';
    });

    try {
      await device.connect(timeout: const Duration(seconds: 10));
      if (mounted) {
        setState(() => _phase = _Phase.credentials);
        _scanWifi();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.error;
          _statusMessage = 'No se pudo conectar. Asegurate de que el dispositivo esté encendido y cerca.';
        });
      }
    }
  }

  Future<void> _sendCredentials() async {
    final ssid = _ssidController.text.trim();
    final pass = _passController.text;
    if (ssid.isEmpty) return;

    setState(() {
      _phase = _Phase.provisioning;
      _statusMessage = 'Enviando credenciales...';
    });

    try {
      final services = await _device!.discoverServices();
      final service = services.firstWhere(
        (s) => s.uuid.toString().toLowerCase() == _serviceUuid,
      );

      BluetoothCharacteristic? ssidChar, passChar, statusChar;
      for (final c in service.characteristics) {
        final uuid = c.uuid.toString().toLowerCase();
        if (uuid == _ssidUuid) ssidChar = c;
        if (uuid == _passUuid) passChar = c;
        if (uuid == _statusUuid) statusChar = c;
      }

      if (ssidChar == null || passChar == null || statusChar == null) {
        throw Exception('Características BLE no encontradas');
      }

      // Subscribirse al status ANTES de escribir
      await statusChar.setNotifyValue(true);
      _statusSub = statusChar.lastValueStream.listen((value) {
        if (value.isEmpty) return;
        final status = utf8.decode(value);
        if (!mounted) return;
        setState(() {
          if (status == 'connecting') {
            _statusMessage = 'Conectando al WiFi...';
          } else if (status == 'ok') {
            _phase = _Phase.success;
            _statusMessage = '¡WiFi configurado! El dispositivo se reiniciará.';
          } else if (status == 'error') {
            _phase = _Phase.error;
            _statusMessage = 'No se pudo conectar al WiFi. Verificá las credenciales.';
          }
        });
      });

      await ssidChar.write(utf8.encode(ssid), withoutResponse: false);
      await Future.delayed(const Duration(milliseconds: 200));
      await passChar.write(utf8.encode(pass), withoutResponse: false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.error;
          _statusMessage = 'Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () => context.pop(),
        ),
        title: const Text('Configurar Dispositivo', style: TextStyle(fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return switch (_phase) {
      _Phase.scanning   => _buildScanning(),
      _Phase.connecting => _buildStatus(Icons.bluetooth_connected, _statusMessage, spinning: true),
      _Phase.credentials => _buildCredentialsForm(),
      _Phase.provisioning => _buildStatus(Icons.wifi_find, _statusMessage, spinning: true),
      _Phase.success    => _buildSuccess(),
      _Phase.error      => _buildErrorState(),
    };
  }

  Widget _buildScanning() {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Icon(Icons.bluetooth_searching, size: 56, color: AppColors.primary),
        const SizedBox(height: 16),
        const Text(
          'Buscando dispositivos...',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Si no aparece "CentroProductividad", seleccioná tu ESP32 de la lista.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 24),
        const LinearProgressIndicator(color: AppColors.primary, backgroundColor: Colors.white10),
        const SizedBox(height: 24),
        if (_scanResults.isEmpty)
          const Expanded(child: Center(child: Text('Sin dispositivos aún...', style: TextStyle(color: Colors.white24))))
        else
          Expanded(
            child: ListView.builder(
              itemCount: _scanResults.length,
              itemBuilder: (context, i) {
                final r = _scanResults[i];
                final name = r.device.platformName.isNotEmpty
                    ? r.device.platformName
                    : r.advertisementData.advName.isNotEmpty
                        ? r.advertisementData.advName
                        : r.device.remoteId.str;
                final isHub = name == _deviceName;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    opacity: isHub ? 0.2 : 0.05,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: InkWell(
                      onTap: () {
                        FlutterBluePlus.stopScan();
                        _connectTo(r.device);
                      },
                      child: Row(
                        children: [
                          Icon(
                            isHub ? Icons.router : Icons.bluetooth,
                            color: isHub ? AppColors.primary : Colors.white38,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: TextStyle(color: isHub ? Colors.white : Colors.white70, fontWeight: isHub ? FontWeight.bold : FontWeight.normal)),
                                Text('RSSI: ${r.rssi} dBm', style: const TextStyle(color: Colors.white24, fontSize: 11)),
                              ],
                            ),
                          ),
                          Text('Conectar', style: TextStyle(color: isHub ? AppColors.primary : Colors.white38, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        PrimaryButton(onPressed: _startScan, child: const Text('Buscar de nuevo')),
      ],
    );
  }

  Widget _buildStatus(IconData icon, String message, {bool spinning = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 80, color: AppColors.primary),
        const SizedBox(height: 32),
        Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          textAlign: TextAlign.center,
        ),
        if (spinning) ...[
          const SizedBox(height: 32),
          const CircularProgressIndicator(color: AppColors.primary),
        ],
      ],
    );
  }

  Widget _buildCredentialsForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.bluetooth_connected, size: 48, color: AppColors.primary),
        const SizedBox(height: 16),
        const Text('Hub conectado', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Seleccioná tu red WiFi y escribí la contraseña.', style: TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 32),

        // Selector de red WiFi
        GlassCard(
          opacity: 0.08,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          borderRadius: BorderRadius.circular(16),
          child: _loadingWifi
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Row(children: [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                    SizedBox(width: 12),
                    Text('Escaneando redes...', style: TextStyle(color: Colors.white54)),
                  ]),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSsid,
                    hint: const Text('Seleccioná una red WiFi', style: TextStyle(color: Colors.white38)),
                    dropdownColor: const Color(0xFF1A1A2E),
                    isExpanded: true,
                    icon: const Icon(Icons.wifi, color: AppColors.primary),
                    items: _wifiNetworks.map((ap) {
                      final bars = ap.level > -50 ? '▰▰▰▰' : ap.level > -65 ? '▰▰▰▱' : ap.level > -80 ? '▰▰▱▱' : '▰▱▱▱';
                      return DropdownMenuItem(
                        value: ap.ssid,
                        child: Text('$bars  ${ap.ssid}', style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedSsid = v;
                        _ssidController.text = v ?? '';
                      });
                    },
                  ),
                ),
        ),

        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _scanWifi,
          icon: const Icon(Icons.refresh, size: 14, color: AppColors.primary),
          label: const Text('Buscar de nuevo', style: TextStyle(color: AppColors.primary, fontSize: 12)),
        ),

        const SizedBox(height: 8),
        GlassTextField(
          controller: _passController,
          label: 'Contraseña WiFi',
          icon: Icons.lock_outline,
          isPassword: true,
        ),

        const Spacer(),
        PrimaryButton(
          onPressed: _selectedSsid == null ? null : _sendCredentials,
          child: const Text('Configurar'),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_outline, size: 80, color: AppColors.success),
        const SizedBox(height: 32),
        const Text(
          '¡Listo!',
          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'El Hub se conectará al WiFi y al broker MQTT automáticamente.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
        const SizedBox(height: 48),
        PrimaryButton(
          onPressed: () => context.go('/'),
          child: const Text('Ir al Dashboard'),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 80, color: AppColors.error),
        const SizedBox(height: 32),
        Text(
          _statusMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
        const SizedBox(height: 48),
        PrimaryButton(
          onPressed: _startScan,
          child: const Text('Intentar de nuevo'),
        ),
      ],
    );
  }
}
