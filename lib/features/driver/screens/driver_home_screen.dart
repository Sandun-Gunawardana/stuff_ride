import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stuff_ride/features/auth/screens/login_screen.dart';
import 'package:stuff_ride/models/vehicle_model.dart';
import 'package:stuff_ride/services/auth_service.dart';
import 'package:stuff_ride/services/firestore_service.dart';
import 'add_vehicle_screen.dart';
import 'driver_bookings_screen.dart';
import 'my_vehicles_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _logout() async {
    await _authService.logoutUser();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final driver = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver Dashboard"),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: driver == null
          ? const Center(child: Text('Please log in'))
          : StreamBuilder<Vehicle?>(
              stream: _firestoreService.getDriverActiveVehicle(driver.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final vehicle = snapshot.data;

                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      "Welcome Driver",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 28),
                    if (vehicle == null)
                      _NoVehicleCard(
                        onAddVehicle: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddVehicleScreen(),
                            ),
                          );
                        },
                      )
                    else
                      _DriverVehicleActions(
                        vehicle: vehicle,
                        onViewVehicle: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MyVehiclesScreen(),
                            ),
                          );
                        },
                        onStartTrip: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DriverBookingsScreen(vehicle: vehicle),
                            ),
                          );
                        },
                        onViewBookings: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DriverBookingsScreen(vehicle: vehicle),
                            ),
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

class _NoVehicleCard extends StatelessWidget {
  final VoidCallback onAddVehicle;

  const _NoVehicleCard({required this.onAddVehicle});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.directions_bus, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'Register your vehicle',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Drivers can keep one active vehicle: the vehicle they are driving.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onAddVehicle,
                icon: const Icon(Icons.add_circle),
                label: const Text('Add Vehicle'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverVehicleActions extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onViewVehicle;
  final VoidCallback onStartTrip;
  final VoidCallback onViewBookings;

  const _DriverVehicleActions({
    required this.vehicle,
    required this.onViewVehicle,
    required this.onStartTrip,
    required this.onViewBookings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
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
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: onStartTrip,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Trip'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 56,
          child: OutlinedButton.icon(
            onPressed: onViewBookings,
            icon: const Icon(Icons.event_seat),
            label: const Text('View Bookings'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 56,
          child: OutlinedButton.icon(
            onPressed: onViewVehicle,
            icon: const Icon(Icons.directions_car),
            label: const Text('Manage Vehicle'),
          ),
        ),
      ],
    );
  }
}
