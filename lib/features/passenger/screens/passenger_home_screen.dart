import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stuff_ride/features/auth/screens/login_screen.dart';
import 'package:stuff_ride/models/vehicle_model.dart';
import 'package:stuff_ride/services/auth_service.dart';
import 'package:stuff_ride/services/firestore_service.dart';
import 'notifications_screen.dart';
import 'passenger_dashboard.dart';
import 'vehicle_detail_screen.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _selectedTabIndex = 0;

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
    final titles = ['Staff Transport', 'My Bookings', 'Settings'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedTabIndex]),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedTabIndex,
        children: [
          _AvailableVehiclesTab(
            auth: _auth,
            firestoreService: _firestoreService,
          ),
          _BookingsTab(auth: _auth, firestoreService: _firestoreService),
          _SettingsTab(onLogout: _logout),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        onTap: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_seat),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _AvailableVehiclesTab extends StatelessWidget {
  final FirebaseAuth auth;
  final FirestoreService firestoreService;

  const _AvailableVehiclesTab({
    required this.auth,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser;

    if (user == null) {
      return const Center(child: Text('Please log in to view vehicles'));
    }

    return FutureBuilder<String>(
      future: firestoreService.getUserCompanyId(user.uid),
      builder: (context, companySnapshot) {
        if (companySnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final companyId =
            companySnapshot.data ?? FirestoreService.defaultCompanyId;

        return StreamBuilder<List<Vehicle>>(
          stream: firestoreService.getCompanyActiveVehicles(companyId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final vehicles = snapshot.data ?? [];

            if (vehicles.isEmpty) {
              return const _EmptyState(
                icon: Icons.directions_bus,
                title: 'No vehicles available',
                message:
                    'Vehicles added by drivers in your company circle will appear here.',
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Available Vehicles',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Showing vehicles from your company circle',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                for (final vehicle in vehicles)
                  _VehicleCard(
                    vehicle: vehicle,
                    actionLabel: 'View',
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
              ],
            );
          },
        );
      },
    );
  }
}

class _BookingsTab extends StatelessWidget {
  final FirebaseAuth auth;
  final FirestoreService firestoreService;

  const _BookingsTab({required this.auth, required this.firestoreService});

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser;

    if (user == null) {
      return const Center(child: Text('Please log in to view bookings'));
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: firestoreService.getPassengerVehicleBookings(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data ?? [];

        if (bookings.isEmpty) {
          return const _EmptyState(
            icon: Icons.event_seat,
            title: 'No booked vehicles yet',
            message: 'Book a seat from the Home tab and it will appear here.',
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Booked Vehicles',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            for (final item in bookings)
              _BookedVehicleCard(
                item: item,
                onUnbook: () async {
                  final booking = item['booking'] as Map<String, dynamic>;
                  final vehicleId = item['vehicleId'] as String;
                  final seatNumber = booking['seatNumber'];

                  if (seatNumber is! int) return;

                  try {
                    await firestoreService.unbookVehicleSeat(
                      vehicleId: vehicleId,
                      passengerId: user.uid,
                      seatNumber: seatNumber,
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Seat $seatNumber unbooked')),
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PassengerDashboard(
                        vehicleId: item['vehicleId'] as String,
                        vehicleData: item['vehicle'] as Map<String, dynamic>,
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final String actionLabel;
  final VoidCallback onTap;

  const _VehicleCard({
    required this.vehicle,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.directions_bus)),
        title: Text(vehicle.vehicleNumber),
        subtitle: Text(
          '${vehicle.vehicleType} • ${vehicle.seatCapacity} seats • ${vehicle.color}',
        ),
        trailing: TextButton(onPressed: onTap, child: Text(actionLabel)),
        onTap: onTap,
      ),
    );
  }
}

class _BookedVehicleCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final VoidCallback onUnbook;

  const _BookedVehicleCard({
    required this.item,
    required this.onTap,
    required this.onUnbook,
  });

  @override
  Widget build(BuildContext context) {
    final booking = item['booking'] as Map<String, dynamic>;
    final vehicle = item['vehicle'] as Map<String, dynamic>;
    final seatNumber = booking['seatNumber'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.event_available)),
        title: Text(vehicle['vehicleNumber'] ?? 'Vehicle'),
        subtitle: Text(
          '${vehicle['vehicleType'] ?? 'Vehicle'} • Seat ${seatNumber ?? '-'}',
        ),
        trailing: TextButton.icon(
          onPressed: onUnbook,
          icon: const Icon(Icons.event_busy),
          label: const Text('Unbook'),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _SettingsTab extends StatefulWidget {
  final VoidCallback onLogout;

  const _SettingsTab({required this.onLogout});

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Trip Notifications'),
                subtitle: const Text('Receive booking and vehicle updates'),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Location Tracking'),
                subtitle: const Text('Allow live trip location features'),
                value: _locationEnabled,
                onChanged: (value) {
                  setState(() {
                    _locationEnabled = value;
                  });
                },
              ),
            ],
          ),
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Language'),
                subtitle: const Text('English'),
                onTap: () =>
                    _showMessage('Language settings will be added soon'),
              ),
              ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('Theme'),
                subtitle: const Text('Light'),
                onTap: () => _showMessage('Theme settings will be added soon'),
              ),
            ],
          ),
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Privacy Policy'),
                onTap: () =>
                    _showMessage('Privacy policy will be available soon'),
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Terms & Conditions'),
                onTap: () => _showMessage('Terms will be available soon'),
              ),
              ListTile(
                leading: const Icon(Icons.support_agent),
                title: const Text('Contact Support'),
                onTap: () => _showMessage('Support contact will be added soon'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            onPressed: widget.onLogout,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
