import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stuff_ride/features/auth/screens/login_screen.dart';
import 'package:stuff_ride/features/passenger/screens/vehicle_list_screen.dart';
import 'package:stuff_ride/models/vehicle_model.dart';
import 'package:stuff_ride/services/auth_service.dart';
import 'package:stuff_ride/services/firestore_service.dart';
import 'notifications_screen.dart';
import 'passenger_dashboard.dart';

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

  Future<void> _openAvailableVehicles() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VehicleListScreen()),
    );
  }

  Future<void> _changeVehicle(Map<String, dynamic> _) async {
    await _openAvailableVehicles();
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Home', 'My Booking', 'Settings'];

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
          _HomeTab(
            auth: _auth,
            firestoreService: _firestoreService,
            onViewVehicles: _openAvailableVehicles,
            onChangeVehicle: _changeVehicle,
            onViewSeat: (bookingData) {
              final vehicle = Vehicle.fromMap(
                Map<String, dynamic>.from(bookingData['vehicle'] as Map),
                bookingData['vehicleId'] as String,
              );
              final ride = Map<String, dynamic>.from(
                bookingData['ride'] as Map,
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PassengerDashboard(
                    vehicleId: vehicle.id,
                    vehicleData: vehicle.toMap(),
                    rideId: bookingData['rideId'] as String,
                    rideData: ride,
                  ),
                ),
              );
            },
          ),
          _BookingsTab(
            auth: _auth,
            firestoreService: _firestoreService,
            onViewVehicles: _openAvailableVehicles,
          ),
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

class _HomeTab extends StatelessWidget {
  final FirebaseAuth auth;
  final FirestoreService firestoreService;
  final VoidCallback onViewVehicles;
  final Future<void> Function(Map<String, dynamic> booking) onChangeVehicle;
  final void Function(Map<String, dynamic> booking) onViewSeat;

  const _HomeTab({
    required this.auth,
    required this.firestoreService,
    required this.onViewVehicles,
    required this.onChangeVehicle,
    required this.onViewSeat,
  });

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser;

    if (user == null) {
      return const Center(child: Text('Please log in to view vehicles'));
    }

    return StreamBuilder<Map<String, dynamic>?>(
      stream: firestoreService.watchPassengerActiveBookingDetails(user.uid),
      builder: (context, bookingSnapshot) {
        if (bookingSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookingData = bookingSnapshot.data;
        if (bookingData == null) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _EmptyState(
                icon: Icons.event_seat,
                title: 'No booking for today',
                message:
                    'Your confirmed ride will appear here after a driver opens the booking window.',
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: onViewVehicles,
                  icon: const Icon(Icons.directions_bus),
                  label: const Text('View available vehicles and rides'),
                ),
              ),
            ],
          );
        }

        final vehicleMap = Map<String, dynamic>.from(
          bookingData['vehicle'] as Map,
        );
        final bookingMap = Map<String, dynamic>.from(
          bookingData['booking'] as Map,
        );
        final vehicle = Vehicle.fromMap(
          vehicleMap,
          bookingData['vehicleId'] as String,
        );
        final rideMap = Map<String, dynamic>.from(bookingData['ride'] as Map);
        final seatNumber = bookingMap['seatNumber'];
        final pickupLocation = bookingMap['pickupLocation'] ?? 'Pickup pending';

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'My active booking',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _ActiveRideCard(
              vehicle: vehicle,
              rideName: rideMap['rideName']?.toString() ?? 'Ride',
              seatNumber: seatNumber is int ? seatNumber : null,
              pickupLocation: pickupLocation.toString(),
              onViewSeat: () => onViewSeat(bookingData),
              onChangeVehicle: () => onChangeVehicle(bookingData),
              locationStream: firestoreService.getLatestVehicleLocation(
                bookingData['rideId'] as String,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BookingsTab extends StatelessWidget {
  final FirebaseAuth auth;
  final FirestoreService firestoreService;
  final VoidCallback onViewVehicles;

  const _BookingsTab({
    required this.auth,
    required this.firestoreService,
    required this.onViewVehicles,
  });

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
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _EmptyState(
                icon: Icons.event_seat,
                title: 'No booked vehicles yet',
                message:
                    'Once your seat is confirmed, your current vehicle appears here.',
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: onViewVehicles,
                  icon: const Icon(Icons.directions_bus),
                  label: const Text('View available vehicles and rides'),
                ),
              ),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Current booking',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'One passenger can keep one active seat at a time.',
              style: Theme.of(context).textTheme.bodyMedium,
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
                      rideId: item['rideId'] as String,
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
                  final ride = item['ride'] as Map<String, dynamic>;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PassengerDashboard(
                        vehicleId: item['vehicleId'] as String,
                        vehicleData: item['vehicle'] as Map<String, dynamic>,
                        rideId: item['rideId'] as String,
                        rideData: ride,
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

class _ActiveRideCard extends StatelessWidget {
  final Vehicle vehicle;
  final String rideName;
  final int? seatNumber;
  final String pickupLocation;
  final VoidCallback onViewSeat;
  final VoidCallback onChangeVehicle;
  final Stream<dynamic> locationStream;

  const _ActiveRideCard({
    required this.vehicle,
    required this.rideName,
    required this.seatNumber,
    required this.pickupLocation,
    required this.onViewSeat,
    required this.onChangeVehicle,
    required this.locationStream,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.directions_bus)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rideName),
                      Text(
                        vehicle.vehicleNumber,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '${vehicle.vehicleType} • Seat ${seatNumber ?? '-'}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Pickup point', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(pickupLocation),
            const SizedBox(height: 16),
            StreamBuilder<dynamic>(
              stream: locationStream,
              builder: (context, snapshot) {
                final data = snapshot.data?.data() as Map<String, dynamic>?;
                final currentLocation = data?['currentLocation'] as String?;
                final road = data?['roadDescription'] as String?;
                final latitude = data?['latitude'];
                final longitude = data?['longitude'];

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live location',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currentLocation ??
                            road ??
                            'Waiting for the driver location update',
                      ),
                      if (latitude is num && longitude is num) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onViewSeat,
                    icon: const Icon(Icons.event_seat),
                    label: const Text('View seat'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onChangeVehicle,
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Change vehicle'),
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
    final ride = item['ride'] as Map<String, dynamic>;
    final seatNumber = booking['seatNumber'];
    final pickup = booking['pickupLocation'] ?? 'Pickup not set';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.event_available)),
        title: Text(ride['rideName'] ?? 'Ride'),
        subtitle: Text(
          '${vehicle['vehicleNumber'] ?? 'Vehicle'} • Seat ${seatNumber ?? '-'}\n$pickup',
        ),
        isThreeLine: true,
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
