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

  factory Booking.fromMap(Map<String, dynamic> data, String documentId) {
    return Booking(
      id: documentId,
      passengerId: data['passengerId'] ?? '',
      tripId: data['tripId'] ?? '',
      seatsBooked: data['seatsBooked'] ?? 0,
      totalFare: (data['totalFare'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'confirmed',
      bookingDate: (data['bookingDate'] as dynamic)?.toDate() ?? DateTime.now(),
      cancelledDate: data['cancelledDate'] != null 
          ? (data['cancelledDate'] as dynamic).toDate() 
          : null,
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
