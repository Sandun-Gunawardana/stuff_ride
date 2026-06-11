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

              final rides = snapshot.data ?? [];
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
                          'Bookings open from ${ride.bookingStartTime}\nStatus: ${ride.status}',
                        ),
                        isThreeLine: true,
                        trailing: FilledButton(
                          onPressed: ride.status == 'scheduled'
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
