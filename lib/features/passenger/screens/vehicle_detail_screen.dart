import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vehicle_rides_screen.dart';

class VehicleDetailScreen extends StatefulWidget {
  final String vehicleId;
  final Map<String, dynamic> vehicleData;

  const VehicleDetailScreen({
    super.key,
    required this.vehicleId,
    required this.vehicleData,
  });

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<DocumentSnapshot> _driverFuture;

  @override
  void initState() {
    super.initState();
    _driverFuture = _firestore
        .collection('users')
        .doc(widget.vehicleData['driverId'])
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FutureBuilder<DocumentSnapshot>(
              future: _driverFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData) {
                  return const Text('Driver information not available');
                }

                final driverData =
                    snapshot.data!.data() as Map<String, dynamic>?;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 28,
                              child: Icon(Icons.directions_bus),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.vehicleData['vehicleNumber'] ??
                                        'Vehicle',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${widget.vehicleData['vehicleType'] ?? 'Vehicle'} • ${widget.vehicleData['color'] ?? 'N/A'}',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          'Seat Capacity',
                          '${widget.vehicleData['seatCapacity'] ?? 'N/A'} seats',
                        ),
                        _buildDetailRow(
                          'Driver',
                          driverData?['fullName'] ?? 'N/A',
                        ),
                        _buildDetailRow(
                          'Mobile',
                          driverData?['mobileNumber'] ?? 'N/A',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VehicleRidesScreen(
                        vehicleId: widget.vehicleId,
                        vehicleData: widget.vehicleData,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.event_seat),
                label: const Text('View Rides & Book'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
