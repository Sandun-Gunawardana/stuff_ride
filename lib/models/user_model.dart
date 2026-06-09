class User {
  final String uid;
  final String fullName;
  final String mobileNumber;
  final String role; // 'passenger', 'driver', 'admin'
  final DateTime createdAt;
  final double rating;
  final bool isApproved; // For drivers

  User({
    required this.uid,
    required this.fullName,
    required this.mobileNumber,
    required this.role,
    required this.createdAt,
    this.rating = 0.0,
    this.isApproved = false,
  });

  factory User.fromMap(Map<String, dynamic> data) {
    return User(
      uid: data['uid'] ?? '',
      fullName: data['fullName'] ?? '',
      mobileNumber: data['mobileNumber'] ?? '',
      role: data['role'] ?? 'passenger',
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      rating: (data['rating'] ?? 0.0).toDouble(),
      isApproved: data['isApproved'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'mobileNumber': mobileNumber,
      'role': role,
      'createdAt': createdAt,
      'rating': rating,
      'isApproved': isApproved,
    };
  }
}
