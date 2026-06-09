import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stuff_ride/models/vehicle_model.dart';
import 'package:stuff_ride/services/firestore_service.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final TextEditingController _vehicleNumberController = TextEditingController();
  final TextEditingController _seatCapacityController = TextEditingController();
  final TextEditingController _vehicleTypeController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _seatCapacityController.dispose();
    _vehicleTypeController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _addVehicle() async {
    if (_vehicleNumberController.text.isEmpty ||
        _seatCapacityController.text.isEmpty ||
        _vehicleTypeController.text.isEmpty ||
        _colorController.text.isEmpty) {
      _showErrorDialog('Please fill all fields');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        Vehicle vehicle = Vehicle(
          id: '', // Firestore will generate ID
          driverId: currentUser.uid,
          vehicleNumber: _vehicleNumberController.text.trim().toUpperCase(),
          seatCapacity: int.parse(_seatCapacityController.text),
          vehicleType: _vehicleTypeController.text.trim(),
          color: _colorController.text.trim(),
          createdAt: DateTime.now(),
          isActive: true,
        );

        await _firestoreService.addVehicle(vehicle);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vehicle added successfully!')),
          );
          Navigator.pop(context);
        }
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
      appBar: AppBar(
        title: const Text("Add Vehicle"),
      ),
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
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
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
                  labelText: "Seat Capacity",
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
                  onPressed: _isLoading ? null : _addVehicle,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Add Vehicle",
                          style: TextStyle(fontSize: 16),
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
