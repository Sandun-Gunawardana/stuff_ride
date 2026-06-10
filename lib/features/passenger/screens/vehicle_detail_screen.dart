import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'passenger_dashboard.dart';

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
      appBar: AppBar(title: const Text("Vehicle Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(Icons.directions_car, size: 80, color: Colors.blue),
            ),
            const SizedBox(height: 30),
            _buildDetailRow(
              "Vehicle Number",
              widget.vehicleData['vehicleNumber'] ?? 'N/A',
            ),
            _buildDetailRow(
              "Vehicle Type",
              widget.vehicleData['vehicleType'] ?? 'N/A',
            ),
            _buildDetailRow(
              "Seat Capacity",
              "${widget.vehicleData['seatCapacity']} seats",
            ),
            _buildDetailRow("Color", widget.vehicleData['color'] ?? 'N/A'),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              "Driver Information",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
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

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      "Driver Name",
                      driverData?['fullName'] ?? 'N/A',
                    ),
                    _buildDetailRow(
                      "Mobile Number",
                      driverData?['mobileNumber'] ?? 'N/A',
                    ),
                    _buildDetailRow(
                      "Rating",
                      "${driverData?['rating'] ?? 0.0} ★",
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PassengerDashboard(
                        vehicleId: widget.vehicleId,
                        vehicleData: widget.vehicleData,
                      ),
                    ),
                  );
                },
                child: const Text(
                  "View Seats & Book",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
