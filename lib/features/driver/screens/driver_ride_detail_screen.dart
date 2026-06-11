import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stuff_ride/models/ride_model.dart';
import 'package:stuff_ride/models/vehicle_model.dart';
import 'package:stuff_ride/services/firestore_service.dart';

class DriverRideDetailScreen extends StatefulWidget {
  final Vehicle vehicle;
  final Ride ride;

  const DriverRideDetailScreen({
    super.key,
    required this.vehicle,
    required this.ride,
  });

  @override
  State<DriverRideDetailScreen> createState() => _DriverRideDetailScreenState();
}

class _DriverRideDetailScreenState extends State<DriverRideDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<Position>? _positionSubscription;
  bool _isStartingRide = false;
  bool _isEndingRide = false;
  bool _isGpsTracking = false;

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
    });

    try {
      Position? currentPosition;
      final hasPermission = await _ensureLocationPermission();

      if (hasPermission) {
        currentPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
      }

      await _firestoreService.startVehicleTrip(
        rideId: ride.id,
        driverId: driver.uid,
        roadDescription: ride.roadDescription,
        currentLocation: ride.currentLocation,
        latitude: currentPosition?.latitude,
        longitude: currentPosition?.longitude,
        accuracy: currentPosition?.accuracy,
        speed: currentPosition == null || currentPosition.speed.isNegative
            ? null
            : currentPosition.speed * 3.6,
      );

      if (hasPermission) {
        await _startGpsTracking(ride.id);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hasPermission
                ? '${ride.rideName} started. Live location is updating.'
                : '${ride.rideName} started. Turn on location permission for live GPS.',
          ),
        ),
      );
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

  Future<void> _endRide(Ride ride) async {
    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End ride?'),
        content: const Text(
          'This will complete the ride and reset its passenger bookings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End Ride'),
          ),
        ],
      ),
    );

    if (shouldEnd != true) return;

    setState(() {
      _isEndingRide = true;
    });

    try {
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      _isGpsTracking = false;
      await _firestoreService.endVehicleTrip(ride.id);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${ride.rideName} completed')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isEndingRide = false;
        });
      }
    }
  }

  Future<void> _startGpsTracking(String rideId) async {
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

    if (mounted) {
      setState(() {
        _isGpsTracking = true;
      });
    }
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
      appBar: AppBar(title: const Text('Ride Details')),
      body: StreamBuilder(
        stream: _firestoreService.getRideState(widget.ride.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data();
          if (data == null) {
            return const Center(child: Text('Ride not found'));
          }

          final ride = Ride.fromMap(data, widget.ride.id);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _RideHeader(
                ride: ride,
                vehicle: widget.vehicle,
                isGpsTracking: _isGpsTracking,
              ),
              const SizedBox(height: 12),
              _RideActions(
                ride: ride,
                isStarting: _isStartingRide,
                isEnding: _isEndingRide,
                onStart: ride.status == 'scheduled'
                    ? () => _startRide(ride)
                    : null,
                onEnd: ride.status == 'ongoing' ? () => _endRide(ride) : null,
              ),
              const SizedBox(height: 16),
              _PassengerBookingsSection(
                bookingsStream: _firestoreService.getVehicleBookingDetails(
                  ride.id,
                ),
                onPickupStatusChanged:
                    ({required bookingId, required pickedUp}) {
                      return _firestoreService.updatePassengerPickupStatus(
                        bookingId: bookingId,
                        pickedUp: pickedUp,
                      );
                    },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RideHeader extends StatelessWidget {
  final Ride ride;
  final Vehicle vehicle;
  final bool isGpsTracking;

  const _RideHeader({
    required this.ride,
    required this.vehicle,
    required this.isGpsTracking,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ride.rideName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                _StatusChip(status: ride.status),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.directions_bus,
              text:
                  '${vehicle.vehicleNumber} • ${vehicle.vehicleType} • ${vehicle.seatCapacity} seats',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.schedule,
              text: 'Bookings open at ${ride.bookingStartTime}',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: isGpsTracking ? Icons.gps_fixed : Icons.gps_not_fixed,
              text: isGpsTracking
                  ? 'Live GPS is updating'
                  : 'Live GPS starts when the ride starts',
            ),
          ],
        ),
      ),
    );
  }
}

class _RideActions extends StatelessWidget {
  final Ride ride;
  final bool isStarting;
  final bool isEnding;
  final VoidCallback? onStart;
  final VoidCallback? onEnd;

  const _RideActions({
    required this.ride,
    required this.isStarting,
    required this.isEnding,
    required this.onStart,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    if (ride.status == 'completed') {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('This ride is completed. Bookings were reset.'),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: isStarting ? null : onStart,
            icon: isStarting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: const Text('Start Ride'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isEnding ? null : onEnd,
            icon: isEnding
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.stop_circle_outlined),
            label: const Text('End Ride'),
          ),
        ),
      ],
    );
  }
}

class _PassengerBookingsSection extends StatelessWidget {
  final Stream<List<Map<String, dynamic>>> bookingsStream;
  final Future<void> Function({
    required String bookingId,
    required bool pickedUp,
  })
  onPickupStatusChanged;

  const _PassengerBookingsSection({
    required this.bookingsStream,
    required this.onPickupStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: bookingsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final bookings = snapshot.data ?? [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Passenger details',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Chip(label: Text('${bookings.length} booked')),
                  ],
                ),
                const SizedBox(height: 8),
                if (bookings.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No seats booked for this ride yet'),
                  )
                else
                  for (final item in bookings)
                    _BookingTile(
                      item: item,
                      onPickupStatusChanged: onPickupStatusChanged,
                    ),
              ],
            );
          },
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
    final mobileNumber = passenger?['mobileNumber'] ?? '';
    final seatNumber = booking['seatNumber'] ?? '-';
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
            : Text('$seatNumber'),
      ),
      title: Text(passengerName.toString(), style: textStyle),
      subtitle: Text(
        [
          'Seat $seatNumber • $pickupLocation',
          if (mobileNumber.toString().isNotEmpty) mobileNumber.toString(),
          pickedUp ? 'Picked up' : 'Still waiting',
        ].join('\n'),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      'ongoing' => Colors.green,
      'completed' => Colors.grey,
      _ => colorScheme.primary,
    };

    return Chip(
      label: Text(status),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      backgroundColor: color.withValues(alpha: 0.12),
    );
  }
}
