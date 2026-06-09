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

  factory Trip.fromMap(Map<String, dynamic> data, String documentId) {
    return Trip(
      id: documentId,
      driverId: data['driverId'] ?? '',
      vehicleId: data['vehicleId'] ?? '',
      routeId: data['routeId'] ?? '',
      departureTime: (data['departureTime'] as dynamic)?.toDate() ?? DateTime.now(),
      arrivalTime: data['arrivalTime'] != null 
          ? (data['arrivalTime'] as dynamic).toDate() 
          : null,
      status: data['status'] ?? 'scheduled',
      availableSeats: data['availableSeats'] ?? 0,
      fare: (data['fare'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
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
