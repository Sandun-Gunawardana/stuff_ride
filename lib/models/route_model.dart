class Route {
  final String id;
  final String driverId;
  final String vehicleId;
  final String routeName;
  final String pickupLocation;
  final String dropoffLocation;
  final List<String> stops; // List of stop locations
  final DateTime createdAt;
  final bool isActive;

  Route({
    required this.id,
    required this.driverId,
    required this.vehicleId,
    required this.routeName,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.stops,
    required this.createdAt,
    this.isActive = true,
  });

  factory Route.fromMap(Map<String, dynamic> data, String documentId) {
    return Route(
      id: documentId,
      driverId: data['driverId'] ?? '',
      vehicleId: data['vehicleId'] ?? '',
      routeName: data['routeName'] ?? '',
      pickupLocation: data['pickupLocation'] ?? '',
      dropoffLocation: data['dropoffLocation'] ?? '',
      stops: List<String>.from(data['stops'] ?? []),
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'vehicleId': vehicleId,
      'routeName': routeName,
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'stops': stops,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }
}
