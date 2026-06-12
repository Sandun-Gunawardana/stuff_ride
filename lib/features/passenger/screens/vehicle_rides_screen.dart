import 'package:flutter/material.dart';
import 'package:stuff_ride/features/passenger/screens/passenger_dashboard.dart';
import 'package:stuff_ride/models/ride_model.dart';
import 'package:stuff_ride/models/vehicle_model.dart';
import 'package:stuff_ride/services/firestore_service.dart';

class VehicleRidesScreen extends StatelessWidget {
  final String vehicleId;
  final Map<String, dynamic> vehicleData;

  VehicleRidesScreen({
    super.key,
    required this.vehicleId,
    required this.vehicleData,
  });

  final FirestoreService _firestoreService = FirestoreService();

  bool _canSelectRide(Ride ride) {
    final bookingOpenAt = ride.bookingOpenAt;
    final bookingWindowOpen =
        bookingOpenAt == null || !DateTime.now().isBefore(bookingOpenAt);
    return bookingWindowOpen &&
        (ride.status == 'scheduled' || ride.status == 'ongoing');
  }

  String _bookingStatusText(Ride ride) {
    final bookingOpenAt = ride.bookingOpenAt;
    if (bookingOpenAt == null || !DateTime.now().isBefore(bookingOpenAt)) {
      return 'Bookings open from ${ride.bookingStartTime}';
    }

    final date =
        '${bookingOpenAt.year.toString().padLeft(4, '0')}-${bookingOpenAt.month.toString().padLeft(2, '0')}-${bookingOpenAt.day.toString().padLeft(2, '0')}';
    final time =
        '${bookingOpenAt.hour.toString().padLeft(2, '0')}:${bookingOpenAt.minute.toString().padLeft(2, '0')}';
    return 'Bookings open $date at $time';
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = Vehicle.fromMap(vehicleData, vehicleId);

    return Scaffold(
      appBar: AppBar(title: const Text('Select Ride')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.directions_bus)),
              title: Text(vehicle.vehicleNumber),
              subtitle: Text(
                '${vehicle.vehicleType} • ${vehicle.seatCapacity} seats',
              ),
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Ride>>(
            stream: _firestoreService.getVehicleRides(vehicleId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final rides = (snapshot.data ?? [])
                  .where((ride) => ride.status != 'completed')
                  .where((ride) => ride.status != 'cancelled')
                  .toList();
              if (rides.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('No rides available for this vehicle'),
                  ),
                );
              }

              return Column(
                children: [
                  for (final ride in rides)
                    Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.schedule),
                        ),
                        title: Text(ride.rideName),
                        subtitle: Text(
                          '${_bookingStatusText(ride)}\nStatus: ${ride.status}',
                        ),
                        isThreeLine: true,
                        trailing: FilledButton(
                          onPressed: _canSelectRide(ride)
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PassengerDashboard(
                                        vehicleId: vehicleId,
                                        vehicleData: vehicleData,
                                        rideId: ride.id,
                                        rideData: ride.toMap(),
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          child: const Text('Select'),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
