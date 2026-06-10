import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stuff_ride/models/vehicle_model.dart';
import 'package:stuff_ride/services/firestore_service.dart';

class DriverBookingsScreen extends StatefulWidget {
  final Vehicle vehicle;

  const DriverBookingsScreen({super.key, required this.vehicle});

  @override
  State<DriverBookingsScreen> createState() => _DriverBookingsScreenState();
}

class _DriverBookingsScreenState extends State<DriverBookingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _roadController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  StreamSubscription<Position>? _positionSubscription;
  bool _isUpdatingTrip = false;
  bool _isGpsTracking = false;

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _roadController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _startTrip() async {
    await _saveTripProgress(startTrip: true);
  }

  Future<void> _updateProgress() async {
    await _saveTripProgress(startTrip: false);
  }

  Future<void> _saveTripProgress({required bool startTrip}) async {
    final driver = _auth.currentUser;
    final road = _roadController.text.trim();
    final location = _locationController.text.trim();

    if (driver == null) return;

    if (road.isEmpty || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter current road and location')),
      );
      return;
    }

    setState(() {
      _isUpdatingTrip = true;
    });

    try {
      if (startTrip) {
        await _firestoreService.startVehicleTrip(
          vehicleId: widget.vehicle.id,
          driverId: driver.uid,
          roadDescription: road,
          currentLocation: location,
        );
        await _startGpsTracking();
      } else {
        await _firestoreService.updateVehicleTripProgress(
          vehicleId: widget.vehicle.id,
          roadDescription: road,
          currentLocation: location,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(startTrip ? 'Trip started' : 'Trip updated')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingTrip = false;
        });
      }
    }
  }

  Future<void> _startGpsTracking() async {
    final hasPermission = await _ensureLocationPermission();
    if (!hasPermission) return;

    await _positionSubscription?.cancel();

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: settings).listen(
          (position) async {
            await _firestoreService.updateVehicleGpsLocation(
              vehicleId: widget.vehicle.id,
              latitude: position.latitude,
              longitude: position.longitude,
              accuracy: position.accuracy,
              speed: position.speed.isNegative ? null : position.speed * 3.6,
              roadDescription: _roadController.text.trim(),
              currentLocation: _locationController.text.trim(),
            );
          },
          onError: (error) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('GPS tracking error: $error')),
            );
          },
        );

    final currentPosition = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    await _firestoreService.updateVehicleGpsLocation(
      vehicleId: widget.vehicle.id,
      latitude: currentPosition.latitude,
      longitude: currentPosition.longitude,
      accuracy: currentPosition.accuracy,
      speed: currentPosition.speed.isNegative
          ? null
          : currentPosition.speed * 3.6,
      roadDescription: _roadController.text.trim(),
      currentLocation: _locationController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isGpsTracking = true;
      });
    }
  }

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Turn on device location services')),
        );
      }
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required')),
        );
      }
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Bookings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _VehicleHeader(vehicle: widget.vehicle),
            const SizedBox(height: 12),
            _TripProgressCard(
              vehicleId: widget.vehicle.id,
              roadController: _roadController,
              locationController: _locationController,
              firestoreService: _firestoreService,
              isUpdating: _isUpdatingTrip,
              isGpsTracking: _isGpsTracking,
              onStartTrip: _startTrip,
              onUpdateProgress: _updateProgress,
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getVehicleBookingDetails(
                widget.vehicle.id,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final bookings = snapshot.data ?? [];

                if (bookings.isEmpty) {
                  return const _EmptyBookings();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Booked Seats',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    for (final item in bookings) _BookingTile(item: item),
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

class _TripProgressCard extends StatelessWidget {
  final String vehicleId;
  final TextEditingController roadController;
  final TextEditingController locationController;
  final FirestoreService firestoreService;
  final bool isUpdating;
  final bool isGpsTracking;
  final VoidCallback onStartTrip;
  final VoidCallback onUpdateProgress;

  const _TripProgressCard({
    required this.vehicleId,
    required this.roadController,
    required this.locationController,
    required this.firestoreService,
    required this.isUpdating,
    required this.isGpsTracking,
    required this.onStartTrip,
    required this.onUpdateProgress,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<dynamic>(
      stream: firestoreService.getVehicleTripState(vehicleId),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final isOngoing = data?['status'] == 'ongoing';

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isOngoing ? 'Trip is ongoing' : 'Trip not started',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Icon(
                      isOngoing ? Icons.play_circle : Icons.pause_circle,
                      color: isOngoing ? Colors.green : Colors.grey,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isGpsTracking ? Icons.gps_fixed : Icons.gps_off,
                      size: 18,
                      color: isGpsTracking ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isGpsTracking
                          ? 'Live GPS is updating for passengers'
                          : 'Live GPS starts when trip starts',
                    ),
                  ],
                ),
                if (data?['roadDescription'] != null) ...[
                  const SizedBox(height: 8),
                  Text('Road: ${data!['roadDescription']}'),
                ],
                if (data?['currentLocation'] != null)
                  Text('Current: ${data!['currentLocation']}'),
                const SizedBox(height: 12),
                TextField(
                  controller: roadController,
                  decoration: const InputDecoration(
                    labelText: 'Road / route vehicle is going',
                    hintText: 'e.g., Galle Road toward Fort',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Current location',
                    hintText: 'e.g., Near main gate',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isUpdating ? null : onStartTrip,
                        icon: const Icon(Icons.flag),
                        label: const Text('Start Trip'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isUpdating ? null : onUpdateProgress,
                        icon: const Icon(Icons.route),
                        label: const Text('Update'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BookingTile extends StatelessWidget {
  final Map<String, dynamic> item;

  const _BookingTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final booking = item['booking'] as Map<String, dynamic>;
    final passenger = item['passenger'] as Map<String, dynamic>?;
    final seatNumber = booking['seatNumber'] ?? '-';
    final pickup = booking['pickupLocation'] ?? 'Pickup not set';
    final lat = booking['pickupLatitude'];
    final lng = booking['pickupLongitude'];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(child: Text('$seatNumber')),
        title: Text(passenger?['fullName'] ?? 'Passenger'),
        subtitle: Text(
          lat is num && lng is num
              ? '$pickup\n${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'
              : pickup,
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.location_on),
      ),
    );
  }
}

class _EmptyBookings extends StatelessWidget {
  const _EmptyBookings();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.event_seat, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('No passenger bookings yet'),
          ],
        ),
      ),
    );
  }
}
