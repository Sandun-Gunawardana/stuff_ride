import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:stuff_ride/models/user_model.dart';
import 'package:stuff_ride/models/vehicle_model.dart';
import 'package:stuff_ride/models/ride_model.dart';
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

  DocumentReference<Map<String, dynamic>> _rideRef(String rideId) {
    return _firestore.collection('rides').doc(rideId);
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

  bool _canBookRideStatus(String? status) {
    return status == 'scheduled' || status == 'ongoing';
  }

  DateTime? _nullableDateFromValue(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return value.toDate();
  }

  String _formatBookingOpenAt(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  DateTime _nextBookingOpenAt({
    required String bookingStartTime,
    required String renewalFrequency,
    required DateTime from,
  }) {
    final parts = bookingStartTime.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 6 : 6;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    var next = DateTime(from.year, from.month, from.day, hour, minute);

    if (renewalFrequency == 'weekly') {
      next = next.add(const Duration(days: 7));
      while (!next.isAfter(from)) {
        next = next.add(const Duration(days: 7));
      }
      return next;
    }

    do {
      next = next.add(const Duration(days: 1));
    } while (renewalFrequency == 'weekdays' &&
        (next.weekday == DateTime.saturday || next.weekday == DateTime.sunday));

    return next;
  }

  int _bookableSeatCount(Map<String, dynamic> vehicleData) {
    final layout = vehicleData['seatLayout'];
    if (layout is List && layout.isNotEmpty) {
      final physicalSeatCount = layout.fold<int>(0, (total, row) {
        if (row is! Map) return total;
        final seats = row['seats'];
        return total + (seats is num ? seats.toInt() : 0);
      });
      return physicalSeatCount > 0 ? physicalSeatCount - 1 : 0;
    }

    final seatCapacity = vehicleData['seatCapacity'];
    final physicalSeatCount = seatCapacity is num ? seatCapacity.toInt() : 0;
    return physicalSeatCount > 0 ? physicalSeatCount - 1 : 0;
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

  // ===== RIDE OPERATIONS =====
  Future<String> addRide(Ride ride) async {
    final existingRides = await _firestore
        .collection('rides')
        .where('vehicleId', isEqualTo: ride.vehicleId)
        .where('rideName', isEqualTo: ride.rideName)
        .get();

    if (existingRides.docs.isNotEmpty) {
      throw Exception('That ride already exists for this vehicle');
    }

    final docRef = await _firestore.collection('rides').add(ride.toMap());
    return docRef.id;
  }

  Future<void> updateRide(Ride ride) async {
    await _firestore.collection('rides').doc(ride.id).update(ride.toMap());
  }

  Future<void> deleteRide(String rideId) async {
    await _clearRideBookings(rideId);
    await _rideRef(rideId).delete();
  }

  Future<void> _renewRideIfNeeded(Map<String, dynamic>? rideData) async {
    if (rideData == null || rideData['renewEnabled'] != true) return;

    final driverId = rideData['driverId'] as String? ?? '';
    final vehicleId = rideData['vehicleId'] as String? ?? '';
    final companyId = rideData['companyId'] as String? ?? defaultCompanyId;
    final rideName = rideData['rideName'] as String? ?? '';

    if (driverId.isEmpty || vehicleId.isEmpty || rideName.isEmpty) return;

    final now = DateTime.now();
    final bookingStartTime = rideData['bookingStartTime'] as String? ?? '06:00';
    final renewalFrequency = rideData['renewalFrequency'] as String? ?? 'daily';
    final bookingOpenAt = _nextBookingOpenAt(
      bookingStartTime: bookingStartTime,
      renewalFrequency: renewalFrequency,
      from: now,
    );

    await _firestore.collection('rides').add({
      'driverId': driverId,
      'vehicleId': vehicleId,
      'companyId': companyId,
      'rideName': rideName,
      'bookingStartTime': bookingStartTime,
      'status': 'scheduled',
      'renewEnabled': true,
      'renewalFrequency': renewalFrequency,
      'bookingOpenAt': Timestamp.fromDate(bookingOpenAt.toUtc()),
      'roadDescription': '',
      'currentLocation': '',
      'lastLatitude': null,
      'lastLongitude': null,
      'lastAccuracy': null,
      'lastSpeed': null,
      'createdAt': Timestamp.fromDate(now.toUtc()),
      'startedAt': null,
      'endedAt': null,
    });
  }

  Stream<List<Ride>> getDriverRides(String driverId) {
    return _firestore
        .collection('rides')
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) {
          final rides = snapshot.docs
              .map((doc) => Ride.fromMap(doc.data(), doc.id))
              .toList();
          rides.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return rides;
        });
  }

  Stream<List<Ride>> getVehicleRides(String vehicleId) {
    return _firestore
        .collection('rides')
        .where('vehicleId', isEqualTo: vehicleId)
        .snapshots()
        .map((snapshot) {
          final rides = snapshot.docs
              .map((doc) => Ride.fromMap(doc.data(), doc.id))
              .toList();
          rides.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return rides;
        });
  }

  Stream<Ride?> getOngoingRideForVehicle(String vehicleId) {
    return _firestore
        .collection('rides')
        .where('vehicleId', isEqualTo: vehicleId)
        .where('status', isEqualTo: 'ongoing')
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          final doc = snapshot.docs.first;
          return Ride.fromMap(doc.data(), doc.id);
        });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getRideState(String rideId) {
    return _rideRef(rideId).snapshots();
  }

  Future<void> startRide({
    required String rideId,
    required String driverId,
    String roadDescription = '',
    String currentLocation = '',
    double? latitude,
    double? longitude,
    double? accuracy,
    double? speed,
  }) async {
    final now = DateTime.now().toUtc();
    await _rideRef(rideId).set({
      'status': 'ongoing',
      'driverId': driverId,
      'roadDescription': roadDescription,
      'currentLocation': currentLocation,
      'lastLatitude': latitude,
      'lastLongitude': longitude,
      'lastAccuracy': accuracy,
      'lastSpeed': speed,
      'startedAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));
  }

  Future<void> updateRideGpsLocation({
    required String rideId,
    required double latitude,
    required double longitude,
    required double accuracy,
    double? speed,
    String? roadDescription,
    String? currentLocation,
  }) async {
    final now = DateTime.now().toUtc();
    final payload = <String, dynamic>{
      'lastLatitude': latitude,
      'lastLongitude': longitude,
      'lastAccuracy': accuracy,
      'lastSpeed': speed,
      'updatedAt': Timestamp.fromDate(now),
    };

    if (roadDescription != null) payload['roadDescription'] = roadDescription;
    if (currentLocation != null) payload['currentLocation'] = currentLocation;

    await _rideRef(rideId).set(payload, SetOptions(merge: true));
  }

  Future<void> endRide(String rideId) async {
    final rideSnapshot = await _rideRef(rideId).get();
    final rideData = rideSnapshot.data();
    await _clearRideBookings(rideId);
    await _rideRef(rideId).delete();
    await _renewRideIfNeeded(rideData);
  }

  Future<void> _clearRideBookings(String rideId) async {
    final confirmedBookings = await _firestore
        .collection('bookings')
        .where('rideId', isEqualTo: rideId)
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

      final rideId =
          (booking['rideId'] as String?) ??
          (booking['tripId'] as String?) ??
          '';
      if (rideId.isEmpty) {
        return null;
      }

      final rideDoc = await _rideRef(rideId).get();
      final ride = rideDoc.data();
      if (ride == null) {
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
        'rideId': rideId,
        'ride': ride,
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

  Stream<List<Map<String, dynamic>>> getVehicleBookingDetails(String rideId) {
    return _firestore
        .collection('bookings')
        .where('rideId', isEqualTo: rideId)
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

  Stream<Set<int>> getBookedVehicleSeats(String rideId) {
    return _firestore
        .collection('bookings')
        .where('rideId', isEqualTo: rideId)
        .where('status', isEqualTo: 'confirmed')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => doc.data()['seatNumber'])
              .whereType<int>()
              .toSet();
        });
  }

  Stream<Map<int, String>> getVehicleSeatPassengers(String rideId) {
    return _firestore
        .collection('bookings')
        .where('rideId', isEqualTo: rideId)
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
    required String rideId,
    required String passengerId,
    required String passengerName,
    required int seatNumber,
    required String pickupLocation,
    required double pickupLatitude,
    required double pickupLongitude,
  }) async {
    final rideSnapshot = await _rideRef(rideId).get();
    final rideData = rideSnapshot.data();
    if (!rideSnapshot.exists || rideData == null) {
      throw Exception('Ride not found');
    }

    final bookingStartTime =
        (rideData['bookingStartTime'] as String?) ?? '06:00';
    final bookingOpenAt = _nullableDateFromValue(rideData['bookingOpenAt']);
    final now = DateTime.now();

    if (bookingOpenAt != null && now.isBefore(bookingOpenAt)) {
      throw Exception(
        'Bookings open at ${_formatBookingOpenAt(bookingOpenAt)}',
      );
    }

    if (bookingOpenAt == null && !_isBookingOpenNow(bookingStartTime, now)) {
      throw Exception('Bookings open at $bookingStartTime');
    }

    if (!_canBookRideStatus(rideData['status'] as String?)) {
      throw Exception('Bookings are closed for this ride');
    }

    final vehicleSnapshot = await _firestore
        .collection('vehicles')
        .doc(vehicleId)
        .get();
    final vehicleData = vehicleSnapshot.data();
    if (!vehicleSnapshot.exists || vehicleData == null) {
      throw Exception('Vehicle not found');
    }

    final bookableSeatCount = _bookableSeatCount(vehicleData);
    if (seatNumber < 1 || seatNumber > bookableSeatCount) {
      throw Exception('This seat cannot be booked');
    }

    final bookingDate = DateTime.now().toUtc();
    final bookingRef = _bookingRef(rideId, seatNumber);
    final activeRef = _passengerActiveBookingRef(passengerId);

    await _firestore.runTransaction((transaction) async {
      final bookingSnapshot = await transaction.get(bookingRef);
      final bookingData = bookingSnapshot.data();
      final activeSnapshot = await transaction.get(activeRef);
      final activeData = activeSnapshot.data();

      if (activeSnapshot.exists && activeData != null) {
        final oldRideId = activeData['rideId'] as String?;
        final oldVehicleId = activeData['vehicleId'] as String?;
        final oldSeatNumber = activeData['seatNumber'] as int?;

        if (oldRideId != null &&
            oldVehicleId != null &&
            oldSeatNumber != null &&
            (oldRideId != rideId || oldSeatNumber != seatNumber)) {
          transaction.set(_bookingRef(oldRideId, oldSeatNumber), {
            'status': 'cancelled',
            'cancelledDate': Timestamp.fromDate(bookingDate),
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
        'rideId': rideId,
        'passengerId': passengerId,
        'passengerName': passengerName,
        'seatNumber': seatNumber,
        'pickupLocation': pickupLocation,
        'pickupLatitude': pickupLatitude,
        'pickupLongitude': pickupLongitude,
        'seatsBooked': 1,
        'totalFare': 0.0,
        'status': 'confirmed',
        'pickupStatus': 'waiting',
        'pickedUp': false,
        'bookingDate': Timestamp.fromDate(bookingDate),
      };

      transaction.set(bookingRef, bookingPayload);
      transaction.set(activeRef, {
        'bookingId': bookingRef.id,
        'vehicleId': vehicleId,
        'rideId': rideId,
        'passengerId': passengerId,
        'passengerName': passengerName,
        'seatNumber': seatNumber,
        'pickupLocation': pickupLocation,
        'pickupLatitude': pickupLatitude,
        'pickupLongitude': pickupLongitude,
        'pickupStatus': 'waiting',
        'pickedUp': false,
        'bookingDate': Timestamp.fromDate(bookingDate),
      });
    });
  }

  Future<void> updatePassengerPickupStatus({
    required String bookingId,
    required bool pickedUp,
  }) async {
    final now = DateTime.now().toUtc();
    final update = <String, dynamic>{
      'pickedUp': pickedUp,
      'pickupStatus': pickedUp ? 'picked' : 'waiting',
      'pickupStatusUpdatedAt': Timestamp.fromDate(now),
      'pickedUpAt': pickedUp ? Timestamp.fromDate(now) : null,
    };

    await _firestore.collection('bookings').doc(bookingId).update(update);
  }

  Future<void> unbookVehicleSeat({
    required String vehicleId,
    required String rideId,
    required String passengerId,
    required int seatNumber,
  }) async {
    final bookingRef = _bookingRef(rideId, seatNumber);
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
        final activeRideId = activeData['rideId'] as String?;
        final activeVehicleId = activeData['vehicleId'] as String?;
        final activeSeat = activeData['seatNumber'] as int?;
        if (activeRideId == rideId &&
            activeVehicleId == vehicleId &&
            activeSeat == seatNumber) {
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
    String rideId,
  ) {
    return _rideRef(rideId).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getVehicleTripState(
    String rideId,
  ) {
    return _rideRef(rideId).snapshots();
  }

  Future<void> startVehicleTrip({
    required String rideId,
    required String driverId,
    required String roadDescription,
    required String currentLocation,
    double? latitude,
    double? longitude,
    double? accuracy,
    double? speed,
  }) async {
    final now = DateTime.now().toUtc();
    await _rideRef(rideId).set({
      'rideId': rideId,
      'driverId': driverId,
      'status': 'ongoing',
      'roadDescription': roadDescription,
      'currentLocation': currentLocation,
      'lastLatitude': latitude,
      'lastLongitude': longitude,
      'lastAccuracy': accuracy,
      'lastSpeed': speed,
      'startedAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));
  }

  Future<void> updateVehicleTripProgress({
    required String rideId,
    required String roadDescription,
    required String currentLocation,
  }) async {
    final now = DateTime.now().toUtc();

    await _rideRef(rideId).set({
      'roadDescription': roadDescription,
      'currentLocation': currentLocation,
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));
  }

  Future<void> updateVehicleGpsLocation({
    required String rideId,
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

    await _rideRef(rideId).set(locationPayload, SetOptions(merge: true));
    await _rideRef(rideId).set({
      'lastLatitude': latitude,
      'lastLongitude': longitude,
      'lastAccuracy': accuracy,
      'lastSpeed': speed,
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));
  }

  Future<void> endVehicleTrip(String rideId) async {
    final rideSnapshot = await _rideRef(rideId).get();
    final rideData = rideSnapshot.data();
    await _clearVehicleBookings(rideId);
    await _rideRef(rideId).delete();
    await _renewRideIfNeeded(rideData);
  }

  Future<void> _clearVehicleBookings(String rideId) async {
    final confirmedBookings = await _firestore
        .collection('bookings')
        .where('rideId', isEqualTo: rideId)
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
