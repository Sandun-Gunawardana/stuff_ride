import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stuff_ride/models/user_model.dart';
import 'package:stuff_ride/models/vehicle_model.dart';
import 'package:stuff_ride/models/route_model.dart';
import 'package:stuff_ride/models/trip_model.dart';
import 'package:stuff_ride/models/booking_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===== USER OPERATIONS =====
  Future<void> createUser(User user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<User?> getUserById(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return User.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  Future<void> updateUser(User user) async {
    await _firestore.collection('users').doc(user.uid).update(user.toMap());
  }

  // ===== VEHICLE OPERATIONS =====
  Future<String> addVehicle(Vehicle vehicle) async {
    DocumentReference docRef = await _firestore.collection('vehicles').add(vehicle.toMap());
    return docRef.id;
  }

  Stream<List<Vehicle>> getDriverVehicles(String driverId) {
    return _firestore
        .collection('vehicles')
        .where('driverId', isEqualTo: driverId)
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

  Future<void> updateVehicle(Vehicle vehicle) async {
    await _firestore.collection('vehicles').doc(vehicle.id).update(vehicle.toMap());
  }

  // ===== ROUTE OPERATIONS =====
  Future<String> addRoute(Route route) async {
    DocumentReference docRef = await _firestore.collection('routes').add(route.toMap());
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
    DocumentReference docRef = await _firestore.collection('trips').add(trip.toMap());
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
    DocumentReference docRef = await _firestore.collection('bookings').add(booking.toMap());
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
    await _firestore.collection('bookings').doc(booking.id).update(booking.toMap());
  }
}
