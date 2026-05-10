import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import 'models/profile.dart';

class ProfilesState {
  final List<Profile> profiles;
  final bool isLoading;
  final String? error;

  ProfilesState({
    this.profiles = const [],
    this.isLoading = false,
    this.error,
  });

  ProfilesState copyWith({
    List<Profile>? profiles,
    bool? isLoading,
    String? error,
  }) {
    return ProfilesState(
      profiles: profiles ?? this.profiles,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  Profile? get activeProfile => profiles.any((p) => p.isActive) 
      ? profiles.firstWhere((p) => p.isActive) 
      : null;
}

class ProfilesNotifier extends StateNotifier<ProfilesState> {
  ProfilesNotifier() : super(ProfilesState()) {
    fetchProfiles();
  }

  Future<void> fetchProfiles() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.get(Endpoints.profiles);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final profiles = data.map((e) => Profile.fromJson(e)).toList();
        state = state.copyWith(profiles: profiles, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: 'Error al cargar perfiles');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error de conexión');
    }
  }

  Future<bool> activateProfile(int id) async {
    try {
      final response = await ApiClient.put(Endpoints.activateProfile(id));
      if (response.statusCode == 200) {
        final updatedProfiles = state.profiles.map((p) {
          return p.copyWith(isActive: p.id == id);
        }).toList();
        state = state.copyWith(profiles: updatedProfiles);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createProfile(String name) async {
    try {
      final response = await ApiClient.post(Endpoints.profiles, {'name': name});
      if (response.statusCode == 201) {
        await fetchProfiles();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

final profilesProvider = StateNotifierProvider<ProfilesNotifier, ProfilesState>((ref) {
  return ProfilesNotifier();
});
