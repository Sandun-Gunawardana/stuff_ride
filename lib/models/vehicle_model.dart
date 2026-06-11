class Vehicle {
  final String id;
  final String driverId;
  final String companyId;
  final String vehicleNumber;
  final String vehicleType;
  final int seatCapacity;
  final List<Map<String, dynamic>> seatLayout;
  final String color;
  final DateTime createdAt;
  final bool isActive;

  Vehicle({
    required this.id,
    required this.driverId,
    this.companyId = 'default_company',
    required this.vehicleNumber,
    required this.vehicleType,
    required this.seatCapacity,
    this.seatLayout = const [],
    required this.color,
    required this.createdAt,
    this.isActive = true,
  });

  static DateTime _dateFromValue(dynamic value) {
    if (value is DateTime) return value;
    return value?.toDate() ?? DateTime.now();
  }

  factory Vehicle.fromMap(Map<String, dynamic> data, String documentId) {
    return Vehicle(
      id: documentId,
      driverId: data['driverId'] ?? '',
      companyId: data['companyId'] ?? 'default_company',
      vehicleNumber: data['vehicleNumber'] ?? '',
      vehicleType: data['vehicleType'] ?? '',
      seatCapacity: data['seatCapacity'] ?? 0,
      seatLayout:
          (data['seatLayout'] as List<dynamic>?)
              ?.map((row) => Map<String, dynamic>.from(row as Map))
              .toList() ??
          const [],
      color: data['color'] ?? '',
      createdAt: _dateFromValue(data['createdAt']),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'companyId': companyId,
      'vehicleNumber': vehicleNumber,
      'vehicleType': vehicleType,
      'seatCapacity': seatCapacity,
      'seatLayout': seatLayout,
      'color': color,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }
}
