class Booking {
  final String id;
  final String passengerId;
  final String tripId;
  final int seatsBooked;
  final double totalFare;
  final String status; // 'confirmed', 'cancelled', 'completed'
  final DateTime bookingDate;
  final DateTime? cancelledDate;

  Booking({
    required this.id,
    required this.passengerId,
    required this.tripId,
    required this.seatsBooked,
    required this.totalFare,
    required this.status,
    required this.bookingDate,
    this.cancelledDate,
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

  factory Booking.fromMap(Map<String, dynamic> data, String documentId) {
    return Booking(
      id: documentId,
      passengerId: data['passengerId'] ?? '',
      tripId: data['tripId'] ?? '',
      seatsBooked: data['seatsBooked'] ?? 0,
      totalFare: (data['totalFare'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'confirmed',
      bookingDate: _dateFromValue(data['bookingDate']),
      cancelledDate: _nullableDateFromValue(data['cancelledDate']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'passengerId': passengerId,
      'tripId': tripId,
      'seatsBooked': seatsBooked,
      'totalFare': totalFare,
      'status': status,
      'bookingDate': bookingDate,
      'cancelledDate': cancelledDate,
    };
  }
}
