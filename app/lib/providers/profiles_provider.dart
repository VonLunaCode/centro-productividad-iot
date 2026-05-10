import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile.dart';
import '../services/api_service.dart';

// Profiles list provider
final profilesProvider = FutureProvider<List<Profile>>((ref) async {
  return ApiService.fetchProfiles();
});

// Active profile ID (local state, changed immediately on tap)
final activeProfileIdProvider = StateProvider<int?>((ref) => null);

// Activate a profile: call API then refresh list
final activateProfileProvider =
    Provider<Future<void> Function(int)>((ref) {
  return (int id) async {
    await ApiService.activateProfile(id);
    ref.read(activeProfileIdProvider.notifier).state = id;
    ref.invalidate(profilesProvider);
  };
});

// Calibrate active profile
final calibrateProfileProvider =
    Provider<Future<void> Function(int)>((ref) {
  return (int id) async {
    await ApiService.calibrateProfile(id);
    ref.invalidate(profilesProvider);
  };
});
