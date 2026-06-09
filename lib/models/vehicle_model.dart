class Vehicle {
  final String id;
  final String driverId;
  final String vehicleNumber;
  final String vehicleType;
  final int seatCapacity;
  final String color;
  final DateTime createdAt;
  final bool isActive;

  Vehicle({
    required this.id,
    required this.driverId,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.seatCapacity,
    required this.color,
    required this.createdAt,
    this.isActive = true,
  });

  factory Vehicle.fromMap(Map<String, dynamic> data, String documentId) {
    return Vehicle(
      id: documentId,
      driverId: data['driverId'] ?? '',
      vehicleNumber: data['vehicleNumber'] ?? '',
      vehicleType: data['vehicleType'] ?? '',
      seatCapacity: data['seatCapacity'] ?? 0,
      color: data['color'] ?? '',
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'vehicleNumber': vehicleNumber,
      'vehicleType': vehicleType,
      'seatCapacity': seatCapacity,
      'color': color,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }
}
