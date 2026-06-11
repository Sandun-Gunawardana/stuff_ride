class LiveLocation {
  final String id;
  final String tripId;
  final String driverId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? speed;
  final double? accuracy;

  LiveLocation({
    required this.id,
    required this.tripId,
    required this.driverId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.speed,
    this.accuracy,
  });

  static DateTime _dateFromValue(dynamic value) {
    if (value is DateTime) return value;
    return value?.toDate() ?? DateTime.now();
  }

  factory LiveLocation.fromMap(Map<String, dynamic> data, String documentId) {
    return LiveLocation(
      id: documentId,
      tripId: data['tripId'] ?? '',
      driverId: data['driverId'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      timestamp: _dateFromValue(data['timestamp']),
      speed: data['speed'] != null
          ? (data['speed'] as dynamic).toDouble()
          : null,
      accuracy: data['accuracy'] != null
          ? (data['accuracy'] as dynamic).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'driverId': driverId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
      'speed': speed,
      'accuracy': accuracy,
    };
  }
}
