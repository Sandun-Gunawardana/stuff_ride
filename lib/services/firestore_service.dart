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

  Stream<List<Map<String, dynamic>>> getPassengerVehicleBookings(
    String passengerId,
  ) {
    return _firestore
        .collection('bookings')
        .where('passengerId', isEqualTo: passengerId)
        .where('status', isEqualTo: 'confirmed')
        .snapshots()
        .asyncMap((snapshot) async {
          final items = <Map<String, dynamic>>[];

          for (final doc in snapshot.docs) {
            final booking = doc.data();
            final vehicleId = booking['vehicleId'] as String?;

            if (vehicleId == null || vehicleId.isEmpty) {
              continue;
            }

            final vehicleDoc = await _firestore
                .collection('vehicles')
                .doc(vehicleId)
                .get();
            final vehicle = vehicleDoc.data();

            if (vehicle == null) {
              continue;
            }

            items.add({
              'bookingId': doc.id,
              'booking': booking,
              'vehicleId': vehicleDoc.id,
              'vehicle': vehicle,
            });
          }

          return items;
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
    required int seatNumber,
    required String pickupLocation,
    required double pickupLatitude,
    required double pickupLongitude,
  }) async {
    final bookingRef = _firestore
        .collection('bookings')
        .doc('${vehicleId}_seat_$seatNumber');

    await _firestore.runTransaction((transaction) async {
      final bookingSnapshot = await transaction.get(bookingRef);
      final bookingData = bookingSnapshot.data();

      if (bookingSnapshot.exists && bookingData?['status'] == 'confirmed') {
        throw Exception('Seat $seatNumber is already booked');
      }

      transaction.set(bookingRef, {
        'vehicleId': vehicleId,
        'tripId': vehicleId,
        'passengerId': passengerId,
        'seatNumber': seatNumber,
        'pickupLocation': pickupLocation,
        'pickupLatitude': pickupLatitude,
        'pickupLongitude': pickupLongitude,
        'seatsBooked': 1,
        'totalFare': 0.0,
        'status': 'confirmed',
        'bookingDate': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> unbookVehicleSeat({
    required String vehicleId,
    required String passengerId,
    required int seatNumber,
  }) async {
    final bookingRef = _firestore
        .collection('bookings')
        .doc('${vehicleId}_seat_$seatNumber');

    await _firestore.runTransaction((transaction) async {
      final bookingSnapshot = await transaction.get(bookingRef);
      final bookingData = bookingSnapshot.data();

      if (!bookingSnapshot.exists || bookingData?['status'] != 'confirmed') {
        throw Exception('Seat $seatNumber is not currently booked');
      }

      if (bookingData?['passengerId'] != passengerId) {
        throw Exception('You can only unbook your own seat');
      }

      transaction.update(bookingRef, {
        'status': 'cancelled',
        'cancelledDate': FieldValue.serverTimestamp(),
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
  }) async {
    final now = FieldValue.serverTimestamp();

    await _firestore.collection('vehicleTrips').doc(vehicleId).set({
      'vehicleId': vehicleId,
      'driverId': driverId,
      'status': 'ongoing',
      'roadDescription': roadDescription,
      'currentLocation': currentLocation,
      'startedAt': now,
      'updatedAt': now,
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
    final now = FieldValue.serverTimestamp();

    await _firestore.collection('vehicleTrips').doc(vehicleId).set({
      'roadDescription': roadDescription,
      'currentLocation': currentLocation,
      'updatedAt': now,
    }, SetOptions(merge: true));

    await _firestore.collection('vehicleLocations').doc(vehicleId).set({
      'currentLocation': currentLocation,
      'roadDescription': roadDescription,
      'timestamp': now,
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
    final now = FieldValue.serverTimestamp();

    await _firestore.collection('vehicleLocations').doc(vehicleId).set({
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'speed': speed,
      'roadDescription': ?roadDescription,
      'currentLocation': ?currentLocation,
      'timestamp': now,
    }, SetOptions(merge: true));

    await _firestore.collection('vehicleTrips').doc(vehicleId).set({
      'lastLatitude': latitude,
      'lastLongitude': longitude,
      'lastAccuracy': accuracy,
      'lastSpeed': speed,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }
}
