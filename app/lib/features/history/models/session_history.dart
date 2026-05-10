class SessionHistory {
  final int id;
  final String deviceId;
  final DateTime startTime;
  final DateTime? endTime;

  SessionHistory({
    required this.id,
    required this.deviceId,
    required this.startTime,
    this.endTime,
  });

  factory SessionHistory.fromJson(Map<String, dynamic> json) {
    return SessionHistory(
      id: json['id'],
      deviceId: json['device_id'],
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
    );
  }

  String get duration {
    if (endTime == null) return "En curso";
    final diff = endTime!.difference(startTime);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(diff.inHours)}:${twoDigits(diff.inMinutes.remainder(60))}:${twoDigits(diff.inSeconds.remainder(60))}";
  }
}
