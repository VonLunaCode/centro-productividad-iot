import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsState {
  final bool alertsEnabled;
  final bool vibrationEnabled;

  const SettingsState({
    this.alertsEnabled = true,
    this.vibrationEnabled = true,
  });

  SettingsState copyWith({bool? alertsEnabled, bool? vibrationEnabled}) {
    return SettingsState(
      alertsEnabled: alertsEnabled ?? this.alertsEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  void toggleAlerts(bool value) => state = state.copyWith(alertsEnabled: value);
  void toggleVibration(bool value) => state = state.copyWith(vibrationEnabled: value);
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
