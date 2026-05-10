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
    return Profile(
      id: json['id'],
      name: json['name'],
      isActive: json['is_active'] ?? false,
      thresholds: json['thresholds'],
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
