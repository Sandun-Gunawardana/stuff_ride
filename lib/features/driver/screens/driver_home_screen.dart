import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stuff_ride/features/auth/screens/login_screen.dart';
import 'package:stuff_ride/models/ride_model.dart';
import 'package:stuff_ride/models/vehicle_model.dart';
import 'package:stuff_ride/services/auth_service.dart';
import 'package:stuff_ride/services/firestore_service.dart';

import 'add_ride_screen.dart';
import 'add_vehicle_screen.dart';
import 'driver_ride_detail_screen.dart';
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

  Future<void> _openAddVehicle() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
    );
  }

  Future<void> _openAddRide(Vehicle vehicle) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddRideScreen(vehicle: vehicle)),
    );
  }

  Future<void> _openEditRide(Vehicle vehicle, Ride ride) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddRideScreen(vehicle: vehicle, ride: ride),
      ),
    );
  }

  Future<void> _openRideDetails(Vehicle vehicle, Ride ride) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DriverRideDetailScreen(vehicle: vehicle, ride: ride),
      ),
    );
  }

  Future<void> _deleteRide(Ride ride) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete ride?'),
        content: Text(
          'This will remove ${ride.rideName} and cancel its active bookings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await _firestoreService.deleteRide(ride.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${ride.rideName} deleted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final driver = _auth.currentUser;
    final titles = ['Home', 'Manage Rides', 'Settings'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedTabIndex]),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
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

                return IndexedStack(
                  index: _selectedTabIndex,
                  children: [
                    _DriverHomeTab(
                      vehicle: vehicle,
                      firestoreService: _firestoreService,
                      onAddVehicle: _openAddVehicle,
                      onOpenRide: (ride) {
                        if (vehicle == null) return;
                        _openRideDetails(vehicle, ride);
                      },
                    ),
                    _ManageRidesTab(
                      vehicle: vehicle,
                      firestoreService: _firestoreService,
                      onAddVehicle: _openAddVehicle,
                      onAddRide: vehicle == null
                          ? null
                          : () => _openAddRide(vehicle),
                      onEditRide: (ride) {
                        if (vehicle == null) return;
                        _openEditRide(vehicle, ride);
                      },
                      onDeleteRide: _deleteRide,
                      onOpenRide: (ride) {
                        if (vehicle == null) return;
                        _openRideDetails(vehicle, ride);
                      },
                    ),
                    _DriverSettingsTab(
                      onLogout: _logout,
                      onManageVehicle: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyVehiclesScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
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
          BottomNavigationBarItem(icon: Icon(Icons.route), label: 'Manage'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _DriverHomeTab extends StatelessWidget {
  final Vehicle? vehicle;
  final FirestoreService firestoreService;
  final VoidCallback onAddVehicle;
  final void Function(Ride ride) onOpenRide;

  const _DriverHomeTab({
    required this.vehicle,
    required this.firestoreService,
    required this.onAddVehicle,
    required this.onOpenRide,
  });

  @override
  Widget build(BuildContext context) {
    final activeVehicle = vehicle;

    if (activeVehicle == null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [_NoVehicleCard(onAddVehicle: onAddVehicle)],
      );
    }

    return StreamBuilder<List<Ride>>(
      stream: firestoreService.getVehicleRides(activeVehicle.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final rides = (snapshot.data ?? [])
            .where((ride) => ride.status != 'completed')
            .where((ride) => ride.status != 'cancelled')
            .toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _VehicleHeader(vehicle: activeVehicle),
            const SizedBox(height: 16),
            Text(
              'Not completed rides',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (rides.isEmpty)
              const _EmptyState(
                icon: Icons.route,
                title: 'No active rides',
                message:
                    'Create a ride in Manage Rides. Scheduled and ongoing rides will appear here.',
              )
            else
              for (final ride in rides)
                _HomeRideCard(
                  ride: ride,
                  bookingsStream: firestoreService.getVehicleBookingDetails(
                    ride.id,
                  ),
                  onTap: () => onOpenRide(ride),
                ),
          ],
        );
      },
    );
  }
}

class _ManageRidesTab extends StatelessWidget {
  final Vehicle? vehicle;
  final FirestoreService firestoreService;
  final VoidCallback onAddVehicle;
  final VoidCallback? onAddRide;
  final void Function(Ride ride) onEditRide;
  final Future<void> Function(Ride ride) onDeleteRide;
  final void Function(Ride ride) onOpenRide;

  const _ManageRidesTab({
    required this.vehicle,
    required this.firestoreService,
    required this.onAddVehicle,
    required this.onAddRide,
    required this.onEditRide,
    required this.onDeleteRide,
    required this.onOpenRide,
  });

  @override
  Widget build(BuildContext context) {
    final activeVehicle = vehicle;

    if (activeVehicle == null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [_NoVehicleCard(onAddVehicle: onAddVehicle)],
      );
    }

    return StreamBuilder<List<Ride>>(
      stream: firestoreService.getVehicleRides(activeVehicle.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final rides = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _VehicleHeader(vehicle: activeVehicle),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: onAddRide,
                icon: const Icon(Icons.add),
                label: const Text('Create Ride'),
              ),
            ),
            const SizedBox(height: 16),
            if (rides.isEmpty)
              const _EmptyState(
                icon: Icons.route,
                title: 'No rides added',
                message:
                    'Create morning, evening, or other regular rides for this vehicle.',
              )
            else
              for (final ride in rides)
                _ManageRideCard(
                  ride: ride,
                  bookingsStream: firestoreService.getVehicleBookingDetails(
                    ride.id,
                  ),
                  onOpen: () => onOpenRide(ride),
                  onEdit: ride.status == 'scheduled'
                      ? () => onEditRide(ride)
                      : null,
                  onDelete: ride.status == 'ongoing'
                      ? null
                      : () => onDeleteRide(ride),
                ),
          ],
        );
      },
    );
  }
}

class _DriverSettingsTab extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback onManageVehicle;

  const _DriverSettingsTab({
    required this.onLogout,
    required this.onManageVehicle,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.directions_bus),
            title: const Text('Vehicle'),
            subtitle: const Text('View or edit your registered vehicle'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onManageVehicle,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: onLogout,
          ),
        ),
      ],
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
              child: FilledButton.icon(
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

class _HomeRideCard extends StatelessWidget {
  final Ride ride;
  final Stream<List<Map<String, dynamic>>> bookingsStream;
  final VoidCallback onTap;

  const _HomeRideCard({
    required this.ride,
    required this.bookingsStream,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: onTap,
        leading: CircleAvatar(
          child: Icon(
            ride.status == 'ongoing' ? Icons.navigation : Icons.schedule,
          ),
        ),
        title: Text(ride.rideName),
        subtitle: StreamBuilder<List<Map<String, dynamic>>>(
          stream: bookingsStream,
          builder: (context, snapshot) {
            final bookingCount = snapshot.data?.length ?? 0;
            return Text(
              '${ride.status} • Bookings from ${ride.bookingStartTime} • $bookingCount booked',
            );
          },
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _ManageRideCard extends StatelessWidget {
  final Ride ride;
  final Stream<List<Map<String, dynamic>>> bookingsStream;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ManageRideCard({
    required this.ride,
    required this.bookingsStream,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
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
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: bookingsStream,
                        builder: (context, snapshot) {
                          final bookingCount = snapshot.data?.length ?? 0;
                          return Text(
                            'Bookings from ${ride.bookingStartTime} • $bookingCount booked',
                          );
                        },
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: ride.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.visibility),
                    label: const Text('View'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: onEdit == null
                      ? 'Only scheduled rides can be edited'
                      : 'Edit ride',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: onDelete == null
                      ? 'End the ride before deleting it'
                      : 'Delete ride',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
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
