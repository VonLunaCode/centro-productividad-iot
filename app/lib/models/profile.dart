class Profile {
  final int id;
  final String name;
  final int thresholdMm;
  final String deviceId;
  final bool isActive;

  const Profile({
    required this.id,
    required this.name,
    required this.thresholdMm,
    required this.deviceId,
    required this.isActive,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as int,
        name: json['name'] as String,
        thresholdMm: json['threshold_mm'] as int,
        deviceId: json['device_id'] as String,
        isActive: (json['is_active'] as int) == 1,
      );
}
