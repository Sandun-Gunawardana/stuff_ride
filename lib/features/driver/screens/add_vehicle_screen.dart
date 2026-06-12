import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stuff_ride/models/vehicle_model.dart';
import 'package:stuff_ride/services/firestore_service.dart';
import 'seat_layout_screen.dart';

class AddVehicleScreen extends StatefulWidget {
  final Vehicle? vehicle;

  const AddVehicleScreen({super.key, this.vehicle});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final TextEditingController _vehicleNumberController =
      TextEditingController();
  final TextEditingController _seatCapacityController = TextEditingController();
  final TextEditingController _vehicleTypeController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  List<Map<String, dynamic>> _seatLayout = [];

  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    final vehicle = widget.vehicle;
    if (vehicle != null) {
      _vehicleNumberController.text = vehicle.vehicleNumber;
      _seatCapacityController.text = vehicle.seatCapacity.toString();
      _vehicleTypeController.text = vehicle.vehicleType;
      _colorController.text = vehicle.color;
      _seatLayout = vehicle.seatLayout;
    }
  }

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _seatCapacityController.dispose();
    _vehicleTypeController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _continueToLayout() async {
    if (_vehicleNumberController.text.isEmpty ||
        _seatCapacityController.text.isEmpty ||
        _vehicleTypeController.text.isEmpty ||
        _colorController.text.isEmpty) {
      _showErrorDialog('Please fill all fields');
      return;
    }

    final seatCapacity = int.tryParse(_seatCapacityController.text);
    if (seatCapacity == null || seatCapacity <= 1) {
      _showErrorDialog(
        'Seat capacity must include the driver seat and at least one passenger seat',
      );
      return;
    }

    final layout = await Navigator.push<List<Map<String, dynamic>>>(
      context,
      MaterialPageRoute(
        builder: (_) => SeatLayoutScreen(
          seatCapacity: seatCapacity,
          initialLayout: _seatLayout,
        ),
      ),
    );

    if (layout == null) return;

    _seatLayout = layout;
    await _saveVehicle(seatCapacity: seatCapacity);
  }

  Future<void> _saveVehicle({required int seatCapacity}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        final companyId = await _firestoreService.getUserCompanyId(
          currentUser.uid,
        );
        final existingVehicle = widget.vehicle;

        Vehicle vehicle = Vehicle(
          id: existingVehicle?.id ?? '',
          driverId: currentUser.uid,
          companyId: companyId,
          vehicleNumber: _vehicleNumberController.text.trim().toUpperCase(),
          seatCapacity: seatCapacity,
          seatLayout: _seatLayout,
          vehicleType: _vehicleTypeController.text.trim(),
          color: _colorController.text.trim(),
          createdAt: existingVehicle?.createdAt ?? DateTime.now(),
          isActive: true,
        );

        if (_isEditing) {
          await _firestoreService.updateVehicle(vehicle);
        } else {
          await _firestoreService.addVehicle(vehicle);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing
                    ? 'Vehicle updated successfully!'
                    : 'Vehicle added successfully!',
              ),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        _showErrorDialog('Please log in before adding a vehicle');
      }
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
      appBar: AppBar(title: Text(_isEditing ? "Edit Vehicle" : "Add Vehicle")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  "Register Your Vehicle",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _vehicleNumberController,
                decoration: InputDecoration(
                  labelText: "Vehicle Number",
                  hintText: "e.g., ABC-1234",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _vehicleTypeController,
                decoration: InputDecoration(
                  labelText: "Vehicle Type",
                  hintText: "e.g., Van, Bus, Car",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _seatCapacityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Seat Capacity Including Driver",
                  hintText: "e.g., 5, 10, 20",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _colorController,
                decoration: InputDecoration(
                  labelText: "Vehicle Color",
                  hintText: "e.g., White, Black",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _continueToLayout,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _isEditing
                              ? "Continue to Layout"
                              : "Continue to Seat Layout",
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
