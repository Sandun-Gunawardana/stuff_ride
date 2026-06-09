import 'package:flutter/material.dart';
import 'package:stuff_ride/services/auth_service.dart';
import 'add_vehicle_screen.dart';
import 'my_vehicles_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final AuthService _authService = AuthService();

  void _logout() async {
    await _authService.logoutUser();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),
            const Center(
              child: Text(
                "Welcome Driver",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 50),
            SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_circle),
                label: const Text("Add Vehicle"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddVehicleScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.directions_car),
                label: const Text("My Vehicles"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MyVehiclesScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.route),
                label: const Text("Manage Routes"),
                onPressed: () {
                  // Routes management screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Routes feature coming soon!')),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.schedule),
                label: const Text("Schedule Trip"),
                onPressed: () {
                  // Schedule trip screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Schedule trip feature coming soon!')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
