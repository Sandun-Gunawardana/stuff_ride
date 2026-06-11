class User {
  final String uid;
  final String fullName;
  final String mobileNumber;
  final String role; // 'passenger', 'driver', 'admin'
  final String companyId;
  final DateTime createdAt;
  final double rating;
  final bool isApproved; // For drivers

  User({
    required this.uid,
    required this.fullName,
    required this.mobileNumber,
    required this.role,
    this.companyId = 'default_company',
    required this.createdAt,
    this.rating = 0.0,
    this.isApproved = false,
  });

  static DateTime _dateFromValue(dynamic value) {
    if (value is DateTime) return value;
    return value?.toDate() ?? DateTime.now();
  }

  factory User.fromMap(Map<String, dynamic> data) {
    return User(
      uid: data['uid'] ?? '',
      fullName: data['fullName'] ?? '',
      mobileNumber: data['mobileNumber'] ?? '',
      role: data['role'] ?? 'passenger',
      companyId: data['companyId'] ?? 'default_company',
      createdAt: _dateFromValue(data['createdAt']),
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
      'companyId': companyId,
      'createdAt': createdAt,
      'rating': rating,
      'isApproved': isApproved,
    };
  }
}
