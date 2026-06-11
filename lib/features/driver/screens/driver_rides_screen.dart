import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stuff_ride/features/driver/screens/add_ride_screen.dart';
import 'package:stuff_ride/models/ride_model.dart';
import 'package:stuff_ride/models/vehicle_model.dart';
import 'package:stuff_ride/services/firestore_service.dart';

class DriverRidesScreen extends StatefulWidget {
  final Vehicle vehicle;

  const DriverRidesScreen({super.key, required this.vehicle});

  @override
  State<DriverRidesScreen> createState() => _DriverRidesScreenState();
}

class _DriverRidesScreenState extends State<DriverRidesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<Position>? _positionSubscription;
  bool _isStartingRide = false;
  String? _activeRideId;

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startRide(Ride ride) async {
    final driver = _auth.currentUser;
    if (driver == null) return;

    setState(() {
      _isStartingRide = true;
      _activeRideId = ride.id;
    });

    try {
      await _firestoreService.startVehicleTrip(
        rideId: ride.id,
        driverId: driver.uid,
        roadDescription: '',
        currentLocation: '',
      );
      await _startGpsTracking(ride.id);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${ride.rideName} started')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isStartingRide = false;
        });
      }
    }
  }

  Future<void> _startGpsTracking(String rideId) async {
    final hasPermission = await _ensureLocationPermission();
    if (!hasPermission) return;

    await _positionSubscription?.cancel();

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: settings).listen((
          position,
        ) async {
          await _firestoreService.updateVehicleGpsLocation(
            rideId: rideId,
            latitude: position.latitude,
            longitude: position.longitude,
            accuracy: position.accuracy,
            speed: position.speed.isNegative ? null : position.speed * 3.6,
          );
        });
  }

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Rides')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddRideScreen(vehicle: widget.vehicle),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Ride'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _VehicleHeader(vehicle: widget.vehicle),
            const SizedBox(height: 12),
            StreamBuilder<List<Ride>>(
              stream: _firestoreService.getVehicleRides(widget.vehicle.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rides = snapshot.data ?? [];
                if (rides.isEmpty) {
                  return const _EmptyRides();
                }

                return Column(
                  children: [
                    for (final ride in rides)
                      _RideCard(
                        ride: ride,
                        isStarting: _isStartingRide && _activeRideId == ride.id,
                        firestoreService: _firestoreService,
                        onStart: ride.status == 'scheduled'
                            ? () => _startRide(ride)
                            : null,
                        onEnd: ride.status == 'ongoing'
                            ? () => _firestoreService.endVehicleTrip(ride.id)
                            : null,
                        bookingsStream: _firestoreService
                            .getVehicleBookingDetails(ride.id),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleHeader extends StatelessWidget {
  final Vehicle vehicle;

  const _VehicleHeader({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(child: Icon(Icons.directions_bus)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.vehicleNumber,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '${vehicle.vehicleType} • ${vehicle.seatCapacity} seats',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RideCard extends StatelessWidget {
  final Ride ride;
  final bool isStarting;
  final FirestoreService firestoreService;
  final VoidCallback? onStart;
  final VoidCallback? onEnd;
  final Stream<List<Map<String, dynamic>>> bookingsStream;

  const _RideCard({
    required this.ride,
    required this.isStarting,
    required this.firestoreService,
    required this.onStart,
    required this.onEnd,
    required this.bookingsStream,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.rideName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text('Bookings from ${ride.bookingStartTime}'),
                    ],
                  ),
                ),
                Chip(label: Text(ride.status)),
              ],
            ),
            const SizedBox(height: 12),
            if (ride.status == 'ongoing')
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: bookingsStream,
                builder: (context, snapshot) {
                  final bookings = snapshot.data ?? [];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Passenger pickup list',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (bookings.isEmpty)
                        const Text('No seats booked yet')
                      else
                        for (final item in bookings)
                          _BookingTile(
                            item: item,
                            onPickupStatusChanged:
                                ({required bookingId, required pickedUp}) {
                                  return firestoreService
                                      .updatePassengerPickupStatus(
                                        bookingId: bookingId,
                                        pickedUp: pickedUp,
                                      );
                                },
                          ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onStart == null || isStarting ? null : onStart,
                    icon: isStarting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEnd,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('End'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final Future<void> Function({
    required String bookingId,
    required bool pickedUp,
  })
  onPickupStatusChanged;

  const _BookingTile({required this.item, required this.onPickupStatusChanged});

  @override
  Widget build(BuildContext context) {
    final bookingId = item['bookingId'] as String? ?? '';
    final booking = item['booking'] as Map<String, dynamic>;
    final passenger = item['passenger'] as Map<String, dynamic>?;
    final pickedUp =
        booking['pickedUp'] == true || booking['pickupStatus'] == 'picked';
    final passengerName =
        passenger?['fullName'] ?? booking['passengerName'] ?? 'Passenger';
    final pickupLocation = booking['pickupLocation'] ?? 'Pickup not set';
    final textStyle = pickedUp
        ? const TextStyle(
            decoration: TextDecoration.lineThrough,
            color: Colors.grey,
          )
        : null;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: pickedUp ? Colors.green : null,
        child: pickedUp
            ? const Icon(Icons.check, color: Colors.white)
            : Text('${booking['seatNumber'] ?? '-'}'),
      ),
      title: Text(passengerName, style: textStyle),
      subtitle: Text(
        'Seat ${booking['seatNumber'] ?? '-'} • $pickupLocation\n${pickedUp ? 'Picked up' : 'Still waiting'}',
        style: textStyle,
      ),
      isThreeLine: true,
      trailing: IconButton(
        tooltip: pickedUp ? 'Mark as waiting' : 'Mark as picked up',
        onPressed: bookingId.isEmpty
            ? null
            : () async {
                try {
                  await onPickupStatusChanged(
                    bookingId: bookingId,
                    pickedUp: !pickedUp,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          pickedUp
                              ? '$passengerName marked as waiting'
                              : '$passengerName marked as picked up',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceFirst('Exception: ', ''),
                        ),
                      ),
                    );
                  }
                }
              },
        icon: Icon(pickedUp ? Icons.undo : Icons.person_pin_circle),
      ),
    );
  }
}

class _EmptyRides extends StatelessWidget {
  const _EmptyRides();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(child: Text('No rides added yet')),
    );
  }
}
