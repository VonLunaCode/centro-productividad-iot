import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/profile.dart';

class ApiService {
  static final _client = http.Client();
  static final _base = Uri.parse(ApiConstants.baseUrl);

  static Future<List<Profile>> fetchProfiles() async {
    final res = await _client.get(_base.replace(path: ApiConstants.profiles));
    if (res.statusCode != 200) throw Exception('Failed to load profiles');
    final List<dynamic> list = jsonDecode(res.body);
    return list.map((e) => Profile.fromJson(e)).toList();
  }

  static Future<Profile> activateProfile(int profileId) async {
    final res = await _client.put(
      _base.replace(path: ApiConstants.activateProfile(profileId)),
    );
    if (res.statusCode != 200) throw Exception('Failed to activate profile');
    return Profile.fromJson(jsonDecode(res.body));
  }

  static Future<Profile> calibrateProfile(int profileId) async {
    final res = await _client.put(
      _base.replace(path: ApiConstants.calibrateProfile(profileId)),
    );
    if (res.statusCode != 200) throw Exception('Failed to calibrate');
    return Profile.fromJson(jsonDecode(res.body));
  }
}
