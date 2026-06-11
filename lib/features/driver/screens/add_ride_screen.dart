import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stuff_ride/models/ride_model.dart';
import 'package:stuff_ride/models/vehicle_model.dart';
import 'package:stuff_ride/services/firestore_service.dart';

class AddRideScreen extends StatefulWidget {
  final Vehicle vehicle;

  const AddRideScreen({super.key, required this.vehicle});

  @override
  State<AddRideScreen> createState() => _AddRideScreenState();
}

class _AddRideScreenState extends State<AddRideScreen> {
  final TextEditingController _rideNameController = TextEditingController();
  final TextEditingController _bookingStartTimeController =
      TextEditingController(text: '06:00');
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  @override
  void dispose() {
    _rideNameController.dispose();
    _bookingStartTimeController.dispose();
    super.dispose();
  }

  Future<void> _saveRide() async {
    final rideName = _rideNameController.text.trim();
    final bookingStartTime = _bookingStartTimeController.text.trim();

    if (rideName.isEmpty) {
      _showErrorDialog('Please enter a ride name');
      return;
    }

    if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(bookingStartTime)) {
      _showErrorDialog('Booking start time must use HH:MM format');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _showErrorDialog('Please log in before creating a ride');
        return;
      }

      final companyId = await _firestoreService.getUserCompanyId(
        currentUser.uid,
      );
      final ride = Ride(
        id: '',
        driverId: currentUser.uid,
        vehicleId: widget.vehicle.id,
        companyId: companyId,
        rideName: rideName,
        bookingStartTime: bookingStartTime,
        createdAt: DateTime.now(),
      );

      await _firestoreService.addRide(ride);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride created successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Ride')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              widget.vehicle.vehicleNumber,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.vehicle.vehicleType} • ${widget.vehicle.seatCapacity} seats',
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _rideNameController,
              decoration: InputDecoration(
                labelText: 'Ride Name',
                hintText: 'e.g. Morning ride, Evening ride',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _bookingStartTimeController,
              decoration: InputDecoration(
                labelText: 'Booking Start Time',
                hintText: 'e.g. 06:00',
                helperText:
                    'Passengers can book this ride from this time daily.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveRide,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Ride'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
