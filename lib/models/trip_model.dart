class Trip {
  final String id;
  final String driverId;
  final String vehicleId;
  final String routeId;
  final DateTime departureTime;
  final DateTime? arrivalTime;
  final String status; // 'scheduled', 'ongoing', 'completed', 'cancelled'
  final int availableSeats;
  final double fare;
  final DateTime createdAt;

  Trip({
    required this.id,
    required this.driverId,
    required this.vehicleId,
    required this.routeId,
    required this.departureTime,
    this.arrivalTime,
    required this.status,
    required this.availableSeats,
    required this.fare,
    required this.createdAt,
  });

  static DateTime _dateFromValue(dynamic value) {
    if (value is DateTime) return value;
    return value?.toDate() ?? DateTime.now();
  }

  static DateTime? _nullableDateFromValue(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return value.toDate();
  }

  factory Trip.fromMap(Map<String, dynamic> data, String documentId) {
    return Trip(
      id: documentId,
      driverId: data['driverId'] ?? '',
      vehicleId: data['vehicleId'] ?? '',
      routeId: data['routeId'] ?? '',
      departureTime: _dateFromValue(data['departureTime']),
      arrivalTime: _nullableDateFromValue(data['arrivalTime']),
      status: data['status'] ?? 'scheduled',
      availableSeats: data['availableSeats'] ?? 0,
      fare: (data['fare'] ?? 0.0).toDouble(),
      createdAt: _dateFromValue(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'vehicleId': vehicleId,
      'routeId': routeId,
      'departureTime': departureTime,
      'arrivalTime': arrivalTime,
      'status': status,
      'availableSeats': availableSeats,
      'fare': fare,
      'createdAt': createdAt,
    };
  }
}
