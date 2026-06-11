class Ride {
  final String id;
  final String driverId;
  final String vehicleId;
  final String companyId;
  final String rideName;
  final String bookingStartTime;
  final String status; // scheduled, ongoing, completed, cancelled
  final String roadDescription;
  final String currentLocation;
  final double? lastLatitude;
  final double? lastLongitude;
  final double? lastAccuracy;
  final double? lastSpeed;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;

  Ride({
    required this.id,
    required this.driverId,
    required this.vehicleId,
    required this.companyId,
    required this.rideName,
    required this.bookingStartTime,
    this.status = 'scheduled',
    this.roadDescription = '',
    this.currentLocation = '',
    this.lastLatitude,
    this.lastLongitude,
    this.lastAccuracy,
    this.lastSpeed,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
  });

  factory Ride.fromMap(Map<String, dynamic> data, String documentId) {
    return Ride(
      id: documentId,
      driverId: data['driverId'] ?? '',
      vehicleId: data['vehicleId'] ?? '',
      companyId: data['companyId'] ?? 'default_company',
      rideName: data['rideName'] ?? '',
      bookingStartTime: data['bookingStartTime'] ?? '06:00',
      status: data['status'] ?? 'scheduled',
      roadDescription: data['roadDescription'] ?? '',
      currentLocation: data['currentLocation'] ?? '',
      lastLatitude: (data['lastLatitude'] as num?)?.toDouble(),
      lastLongitude: (data['lastLongitude'] as num?)?.toDouble(),
      lastAccuracy: (data['lastAccuracy'] as num?)?.toDouble(),
      lastSpeed: (data['lastSpeed'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      startedAt: data['startedAt'] != null
          ? (data['startedAt'] as dynamic).toDate()
          : null,
      endedAt: data['endedAt'] != null
          ? (data['endedAt'] as dynamic).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'vehicleId': vehicleId,
      'companyId': companyId,
      'rideName': rideName,
      'bookingStartTime': bookingStartTime,
      'status': status,
      'roadDescription': roadDescription,
      'currentLocation': currentLocation,
      'lastLatitude': lastLatitude,
      'lastLongitude': lastLongitude,
      'lastAccuracy': lastAccuracy,
      'lastSpeed': lastSpeed,
      'createdAt': createdAt,
      'startedAt': startedAt,
      'endedAt': endedAt,
    };
  }
}
