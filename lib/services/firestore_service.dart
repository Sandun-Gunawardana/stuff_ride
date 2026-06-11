import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:stuff_ride/models/user_model.dart';
import 'package:stuff_ride/models/vehicle_model.dart';
import 'package:stuff_ride/models/route_model.dart';
import 'package:stuff_ride/models/trip_model.dart';
import 'package:stuff_ride/models/booking_model.dart';

class FirestoreService {
  static const String defaultCompanyId = 'default_company';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _bookingRef(
    String vehicleId,
    int seatNumber,
  ) {
    return _firestore
        .collection('bookings')
        .doc('${vehicleId}_seat_$seatNumber');
  }

  DocumentReference<Map<String, dynamic>> _passengerActiveBookingRef(
    String passengerId,
  ) {
    return _firestore.collection('passenger_active_bookings').doc(passengerId);
  }

  DocumentReference<Map<String, dynamic>> _vehicleTripRef(String vehicleId) {
    return _firestore.collection('vehicleTrips').doc(vehicleId);
  }

  DateTime _bookingStartDateTimeForToday(
    String bookingStartTime,
    DateTime now,
  ) {
    final parts = bookingStartTime.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 6 : 6;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  bool _isBookingOpenNow(String bookingStartTime, DateTime now) {
    return !now.isBefore(_bookingStartDateTimeForToday(bookingStartTime, now));
  }

  // ===== USER OPERATIONS =====
  Future<void> createUser(User user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<User?> getUserById(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        return User.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  Future<void> updateUser(User user) async {
    await _firestore.collection('users').doc(user.uid).update(user.toMap());
  }

  Future<String> getUserCompanyId(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    return (data?['companyId'] as String?) ?? defaultCompanyId;
  }

  // ===== VEHICLE OPERATIONS =====
  Future<String> addVehicle(Vehicle vehicle) async {
    final existingVehicles = await _firestore
        .collection('vehicles')
        .where('driverId', isEqualTo: vehicle.driverId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (existingVehicles.docs.isNotEmpty) {
      throw Exception('Drivers can only register one active vehicle');
    }

    DocumentReference docRef = await _firestore
        .collection('vehicles')
        .add(vehicle.toMap());
    return docRef.id;
  }

  Stream<List<Vehicle>> getDriverVehicles(String driverId) {
    return _firestore
        .collection('vehicles')
        .where('driverId', isEqualTo: driverId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Vehicle.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Stream<List<Vehicle>> getAllActiveVehicles() {
    return _firestore
        .collection('vehicles')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Vehicle.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Stream<List<Vehicle>> getCompanyActiveVehicles(String companyId) {
    final query = _firestore
        .collection('vehicles')
        .where('isActive', isEqualTo: true);

    if (companyId == defaultCompanyId) {
      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => Vehicle.fromMap(doc.data(), doc.id))
            .toList();
      });
    }

    return query.where('companyId', isEqualTo: companyId).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => Vehicle.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    await _firestore
        .collection('vehicles')
        .doc(vehicle.id)
        .update(vehicle.toMap());
  }

  Future<void> deactivateVehicle(String vehicleId) async {
    await _firestore.collection('vehicles').doc(vehicleId).update({
      'isActive': false,
    });
  }

  Stream<Vehicle?> getDriverActiveVehicle(String driverId) {
    return _firestore
        .collection('vehicles')
        .where('driverId', isEqualTo: driverId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          final doc = snapshot.docs.first;
          return Vehicle.fromMap(doc.data(), doc.id);
        });
  }

  // ===== ROUTE OPERATIONS =====
  Future<String> addRoute(Route route) async {
    DocumentReference docRef = await _firestore
        .collection('routes')
        .add(route.toMap());
    return docRef.id;
  }

  Stream<List<Route>> getDriverRoutes(String driverId) {
    return _firestore
        .collection('routes')
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Route.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> updateRoute(Route route) async {
    await _firestore.collection('routes').doc(route.id).update(route.toMap());
  }

  // ===== TRIP OPERATIONS =====
  Future<String> addTrip(Trip trip) async {
    DocumentReference docRef = await _firestore
        .collection('trips')
        .add(trip.toMap());
    return docRef.id;
  }

  Stream<List<Trip>> getAvailableTrips() {
    return _firestore
        .collection('trips')
        .where('status', isEqualTo: 'scheduled')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Trip.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Stream<List<Trip>> getDriverTrips(String driverId) {
    return _firestore
        .collection('trips')
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Trip.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> updateTrip(Trip trip) async {
    await _firestore.collection('trips').doc(trip.id).update(trip.toMap());
  }

  Future<void> ensureVehicleBookingSessionOpen(String vehicleId) async {
    final tripSnapshot = await _vehicleTripRef(vehicleId).get();
    final tripData = tripSnapshot.data();

    if (!tripSnapshot.exists || tripData == null) {
      return;
    }

    if (tripData['status'] != 'ongoing') {
      return;
    }

    final endsAt = (tripData['bookingSessionEndsAt'] as Timestamp?)?.toDate();
    if (endsAt == null) {
      return;
    }

    final now = DateTime.now().toUtc();
    if (now.isBefore(endsAt.toUtc())) {
      return;
    }

    await _resetVehicleBookingSession(vehicleId: vehicleId, tripData: tripData);
  }

  Future<void> _resetVehicleBookingSession({
    required String vehicleId,
    required Map<String, dynamic> tripData,
  }) async {
    final resetMinutes =
        (tripData['bookingResetMinutes'] as num?)?.toInt() ?? 60;
    final nextSessionIndex =
        (tripData['bookingSessionIndex'] as num?)?.toInt() ?? 1;
    final now = DateTime.now().toUtc();
    final nextEndsAt = now.add(Duration(minutes: resetMinutes));

    final confirmedBookings = await _firestore
        .collection('bookings')
        .where('vehicleId', isEqualTo: vehicleId)
        .where('status', isEqualTo: 'confirmed')
        .get();

    final batch = _firestore.batch();

    for (final doc in confirmedBookings.docs) {
      final data = doc.data();
      final passengerId = data['passengerId'] as String?;

      batch.update(doc.reference, {
        'status': 'cancelled',
        'cancelledDate': Timestamp.fromDate(now),
      });

      if (passengerId != null && passengerId.isNotEmpty) {
        batch.delete(_passengerActiveBookingRef(passengerId));
      }
    }

    batch.set(_vehicleTripRef(vehicleId), {
      'bookingSessionIndex': nextSessionIndex + 1,
      'bookingSessionStartedAt': Timestamp.fromDate(now),
      'bookingSessionEndsAt': Timestamp.fromDate(nextEndsAt),
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  // ===== BOOKING OPERATIONS =====
  Future<String> addBooking(Booking booking) async {
    DocumentReference docRef = await _firestore
        .collection('bookings')
        .add(booking.toMap());
    return docRef.id;
  }

  Stream<List<Booking>> getPassengerBookings(String passengerId) {
    return _firestore
        .collection('bookings')
        .where('passengerId', isEqualTo: passengerId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Booking.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Stream<List<Booking>> getTripBookings(String tripId) {
    return _firestore
        .collection('bookings')
        .where('tripId', isEqualTo: tripId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Booking.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> updateBooking(Booking booking) async {
    await _firestore
        .collection('bookings')
        .doc(booking.id)
        .update(booking.toMap());
  }

  Stream<Map<String, dynamic>?> watchPassengerActiveBookingDetails(
    String passengerId,
  ) {
    return _passengerActiveBookingRef(passengerId).snapshots().asyncMap((
      snapshot,
    ) async {
      final booking = snapshot.data();
      if (!snapshot.exists || booking == null) {
        return null;
      }

      final vehicleId = booking['vehicleId'] as String?;
      if (vehicleId == null || vehicleId.isEmpty) {
        return null;
      }

      final vehicleDoc = await _firestore
          .collection('vehicles')
          .doc(vehicleId)
          .get();
      final vehicle = vehicleDoc.data();
      if (vehicle == null) {
        return null;
      }

      return {
        'bookingId': booking['bookingId'] ?? '',
        'booking': booking,
        'vehicleId': vehicleId,
        'vehicle': vehicle,
      };
    });
  }

  Stream<List<Map<String, dynamic>>> getPassengerVehicleBookings(
    String passengerId,
  ) {
    return watchPassengerActiveBookingDetails(passengerId).map((booking) {
      if (booking == null) return <Map<String, dynamic>>[];
      return <Map<String, dynamic>>[booking];
    });
  }

  Stream<List<Map<String, dynamic>>> getVehicleBookingDetails(
    String vehicleId,
  ) {
    return _firestore
        .collection('bookings')
        .where('vehicleId', isEqualTo: vehicleId)
        .where('status', isEqualTo: 'confirmed')
        .snapshots()
        .asyncMap((snapshot) async {
          final items = <Map<String, dynamic>>[];

          for (final doc in snapshot.docs) {
            final booking = doc.data();
            final passengerId = booking['passengerId'] as String?;
            Map<String, dynamic>? passenger;

            if (passengerId != null && passengerId.isNotEmpty) {
              final passengerDoc = await _firestore
                  .collection('users')
                  .doc(passengerId)
                  .get();
              passenger = passengerDoc.data();
            }

            items.add({
              'bookingId': doc.id,
              'booking': booking,
              'passenger': passenger,
            });
          }

          items.sort((a, b) {
            final aSeat = (a['booking'] as Map<String, dynamic>)['seatNumber'];
            final bSeat = (b['booking'] as Map<String, dynamic>)['seatNumber'];
            return (aSeat is int ? aSeat : 0).compareTo(
              bSeat is int ? bSeat : 0,
            );
          });

          return items;
        });
  }

  Stream<Set<int>> getBookedVehicleSeats(String vehicleId) {
    return _firestore
        .collection('bookings')
        .where('vehicleId', isEqualTo: vehicleId)
        .where('status', isEqualTo: 'confirmed')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => doc.data()['seatNumber'])
              .whereType<int>()
              .toSet();
        });
  }

  Stream<Map<int, String>> getVehicleSeatPassengers(String vehicleId) {
    return _firestore
        .collection('bookings')
        .where('vehicleId', isEqualTo: vehicleId)
        .where('status', isEqualTo: 'confirmed')
        .snapshots()
        .map((snapshot) {
          final seats = <int, String>{};

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final seatNumber = data['seatNumber'];
            final passengerId = data['passengerId'];

            if (seatNumber is int && passengerId is String) {
              seats[seatNumber] = passengerId;
            }
          }

          return seats;
        });
  }

  Future<void> bookVehicleSeat({
    required String vehicleId,
    required String passengerId,
    required String passengerName,
    required int seatNumber,
    required String pickupLocation,
    required double pickupLatitude,
    required double pickupLongitude,
  }) async {
    final vehicleSnapshot = await _firestore
        .collection('vehicles')
        .doc(vehicleId)
        .get();
    final vehicleData = vehicleSnapshot.data();
    if (!vehicleSnapshot.exists || vehicleData == null) {
      throw Exception('Vehicle not found');
    }

    final bookingStartTime =
        (vehicleData['bookingStartTime'] as String?) ?? '06:00';
    if (!_isBookingOpenNow(bookingStartTime, DateTime.now())) {
      throw Exception('Bookings open at $bookingStartTime');
    }

    final tripSnapshot = await _vehicleTripRef(vehicleId).get();
    final tripData = tripSnapshot.data();
    final sessionEndsAt = (tripData?['bookingSessionEndsAt'] as Timestamp?)
        ?.toDate();
    final sessionIndex =
        (tripData?['bookingSessionIndex'] as num?)?.toInt() ?? 1;

    if (tripData != null && tripData['status'] == 'ongoing') {
      await ensureVehicleBookingSessionOpen(vehicleId);
    }

    final now = DateTime.now().toUtc();
    final bookingRef = _bookingRef(vehicleId, seatNumber);
    final activeRef = _passengerActiveBookingRef(passengerId);

    await _firestore.runTransaction((transaction) async {
      final bookingSnapshot = await transaction.get(bookingRef);
      final bookingData = bookingSnapshot.data();
      final activeSnapshot = await transaction.get(activeRef);
      final activeData = activeSnapshot.data();

      if (activeSnapshot.exists && activeData != null) {
        final oldVehicleId = activeData['vehicleId'] as String?;
        final oldSeatNumber = activeData['seatNumber'] as int?;

        if (oldVehicleId != null &&
            oldSeatNumber != null &&
            (oldVehicleId != vehicleId || oldSeatNumber != seatNumber)) {
          transaction.set(_bookingRef(oldVehicleId, oldSeatNumber), {
            'status': 'cancelled',
            'cancelledDate': Timestamp.fromDate(now),
          }, SetOptions(merge: true));
        }
      }

      if (bookingSnapshot.exists &&
          bookingData?['status'] == 'confirmed' &&
          bookingData?['passengerId'] != passengerId) {
        throw Exception('Seat $seatNumber is already booked');
      }

      final bookingPayload = {
        'vehicleId': vehicleId,
        'tripId': vehicleId,
        'passengerId': passengerId,
        'passengerName': passengerName,
        'seatNumber': seatNumber,
        'pickupLocation': pickupLocation,
        'pickupLatitude': pickupLatitude,
        'pickupLongitude': pickupLongitude,
        'seatsBooked': 1,
        'totalFare': 0.0,
        'status': 'confirmed',
        'bookingSessionIndex': sessionIndex,
        'bookingSessionEndsAt': sessionEndsAt == null
            ? null
            : Timestamp.fromDate(sessionEndsAt),
        'bookingDate': Timestamp.fromDate(now),
      };

      transaction.set(bookingRef, bookingPayload);
      transaction.set(activeRef, {
        'bookingId': bookingRef.id,
        'vehicleId': vehicleId,
        'tripId': vehicleId,
        'passengerId': passengerId,
        'passengerName': passengerName,
        'seatNumber': seatNumber,
        'pickupLocation': pickupLocation,
        'pickupLatitude': pickupLatitude,
        'pickupLongitude': pickupLongitude,
        'bookingSessionIndex': sessionIndex,
        'bookingSessionEndsAt': sessionEndsAt == null
            ? null
            : Timestamp.fromDate(sessionEndsAt),
        'bookingDate': Timestamp.fromDate(now),
      });
    });
  }

  Future<void> unbookVehicleSeat({
    required String vehicleId,
    required String passengerId,
    required int seatNumber,
  }) async {
    final bookingRef = _bookingRef(vehicleId, seatNumber);
    final activeRef = _passengerActiveBookingRef(passengerId);
    final now = DateTime.now().toUtc();

    await _firestore.runTransaction((transaction) async {
      final bookingSnapshot = await transaction.get(bookingRef);
      final bookingData = bookingSnapshot.data();
      final activeSnapshot = await transaction.get(activeRef);
      final activeData = activeSnapshot.data();

      if (!bookingSnapshot.exists || bookingData?['status'] != 'confirmed') {
        throw Exception('Seat $seatNumber is not currently booked');
      }

      if (bookingData?['passengerId'] != passengerId) {
        throw Exception('You can only unbook your own seat');
      }

      if (activeSnapshot.exists && activeData != null) {
        final activeVehicleId = activeData['vehicleId'] as String?;
        final activeSeat = activeData['seatNumber'] as int?;
        if (activeVehicleId == vehicleId && activeSeat == seatNumber) {
          transaction.delete(activeRef);
        }
      }

      transaction.update(bookingRef, {
        'status': 'cancelled',
        'cancelledDate': Timestamp.fromDate(now),
      });
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getLatestVehicleLocation(
    String vehicleId,
  ) {
    return _firestore.collection('vehicleLocations').doc(vehicleId).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getVehicleTripState(
    String vehicleId,
  ) {
    return _firestore.collection('vehicleTrips').doc(vehicleId).snapshots();
  }

  Future<void> startVehicleTrip({
    required String vehicleId,
    required String driverId,
    required String roadDescription,
    required String currentLocation,
    required int bookingResetMinutes,
  }) async {
    final now = DateTime.now().toUtc();
    final nextEndsAt = now.add(Duration(minutes: bookingResetMinutes));

    await _vehicleTripRef(vehicleId).set({
      'vehicleId': vehicleId,
      'driverId': driverId,
      'status': 'ongoing',
      'roadDescription': roadDescription,
      'currentLocation': currentLocation,
      'bookingResetMinutes': bookingResetMinutes,
      'bookingSessionIndex': 1,
      'bookingSessionStartedAt': Timestamp.fromDate(now),
      'bookingSessionEndsAt': Timestamp.fromDate(nextEndsAt),
      'startedAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));

    await updateVehicleTripProgress(
      vehicleId: vehicleId,
      roadDescription: roadDescription,
      currentLocation: currentLocation,
    );
  }

  Future<void> updateVehicleTripProgress({
    required String vehicleId,
    required String roadDescription,
    required String currentLocation,
  }) async {
    final now = DateTime.now().toUtc();

    await _vehicleTripRef(vehicleId).set({
      'roadDescription': roadDescription,
      'currentLocation': currentLocation,
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));

    await _firestore.collection('vehicleLocations').doc(vehicleId).set({
      'currentLocation': currentLocation,
      'roadDescription': roadDescription,
      'timestamp': Timestamp.fromDate(now),
    }, SetOptions(merge: true));
  }

  Future<void> updateVehicleGpsLocation({
    required String vehicleId,
    required double latitude,
    required double longitude,
    required double accuracy,
    double? speed,
    String? roadDescription,
    String? currentLocation,
  }) async {
    final now = DateTime.now().toUtc();
    final locationPayload = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'speed': speed,
      'timestamp': Timestamp.fromDate(now),
    };

    if (roadDescription != null) {
      locationPayload['roadDescription'] = roadDescription;
    }

    if (currentLocation != null) {
      locationPayload['currentLocation'] = currentLocation;
    }

    await _firestore
        .collection('vehicleLocations')
        .doc(vehicleId)
        .set(locationPayload, SetOptions(merge: true));

    await _vehicleTripRef(vehicleId).set({
      'lastLatitude': latitude,
      'lastLongitude': longitude,
      'lastAccuracy': accuracy,
      'lastSpeed': speed,
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));
  }

  Future<void> endVehicleTrip(String vehicleId) async {
    final now = DateTime.now().toUtc();
    await _clearVehicleBookings(vehicleId);
    await _vehicleTripRef(vehicleId).set({
      'status': 'completed',
      'endedAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));
  }

  Future<void> _clearVehicleBookings(String vehicleId) async {
    final confirmedBookings = await _firestore
        .collection('bookings')
        .where('vehicleId', isEqualTo: vehicleId)
        .where('status', isEqualTo: 'confirmed')
        .get();

    final batch = _firestore.batch();
    final now = DateTime.now().toUtc();

    for (final doc in confirmedBookings.docs) {
      final data = doc.data();
      final passengerId = data['passengerId'] as String?;

      batch.update(doc.reference, {
        'status': 'cancelled',
        'cancelledDate': Timestamp.fromDate(now),
      });

      if (passengerId != null && passengerId.isNotEmpty) {
        batch.delete(_passengerActiveBookingRef(passengerId));
      }
    }

    await batch.commit();
  }
}
