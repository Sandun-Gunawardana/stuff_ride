import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stuff_ride/models/vehicle_model.dart';
import 'package:stuff_ride/services/firestore_service.dart';
import 'vehicle_detail_screen.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Available Vehicles")),
      body: user == null
          ? const Center(child: Text('Please log in to view vehicles'))
          : FutureBuilder<String>(
              future: _firestoreService.getUserCompanyId(user.uid),
              builder: (context, companySnapshot) {
                if (companySnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final companyId =
                    companySnapshot.data ?? FirestoreService.defaultCompanyId;

                return StreamBuilder<List<Vehicle>>(
                  stream: _firestoreService.getCompanyActiveVehicles(companyId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final vehicles = snapshot.data ?? [];

                    if (vehicles.isEmpty) {
                      return const Center(
                        child: Text(
                          'No vehicles available in your company circle',
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: vehicles.length,
                      itemBuilder: (context, index) {
                        final vehicle = vehicles[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ListTile(
                            leading: const Icon(Icons.directions_car),
                            title: Text(vehicle.vehicleNumber),
                            subtitle: Text(
                              '${vehicle.vehicleType} • ${vehicle.seatCapacity} seats',
                            ),
                            trailing: const Icon(Icons.arrow_forward),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VehicleDetailScreen(
                                    vehicleId: vehicle.id,
                                    vehicleData: vehicle.toMap(),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
