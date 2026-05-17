class Profile {
  final int id;
  final String name;
  final bool isActive;
  final Map<String, dynamic>? thresholds;
  final DateTime? createdAt;

  Profile({
    required this.id,
    required this.name,
    this.isActive = false,
    this.thresholds,
    this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? thresholds;

    final hasThresholds = json['distance_min'] != null ||
        json['temp_min'] != null ||
        json['hum_min'] != null;

    if (hasThresholds) {
      thresholds = {
        'posture': {'min': json['distance_min'], 'max': json['distance_max']},
        'temp': {'min': json['temp_min'], 'max': json['temp_max']},
        'humidity': {'min': json['hum_min'], 'max': json['hum_max']},
        'light': {'min': json['lux_min'], 'max': json['lux_max']},
        'noise': {'min': json['noise_peak_min'], 'max': json['noise_peak_max']},
      };
    }

    return Profile(
      id: json['id'],
      name: json['name'],
      isActive: json['is_active'] ?? false,
      thresholds: thresholds,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Profile copyWith({bool? isActive}) {
    return Profile(
      id: id,
      name: name,
      isActive: isActive ?? this.isActive,
      thresholds: thresholds,
      createdAt: createdAt,
    );
  }
}
