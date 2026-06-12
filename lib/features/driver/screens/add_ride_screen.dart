import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stuff_ride/models/ride_model.dart';
import 'package:stuff_ride/models/vehicle_model.dart';
import 'package:stuff_ride/services/firestore_service.dart';

class AddRideScreen extends StatefulWidget {
  final Vehicle vehicle;
  final Ride? ride;

  const AddRideScreen({super.key, required this.vehicle, this.ride});

  @override
  State<AddRideScreen> createState() => _AddRideScreenState();
}

class _AddRideScreenState extends State<AddRideScreen> {
  late final TextEditingController _rideNameController;
  late final TextEditingController _bookingStartTimeController;
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _renewEnabled = false;
  String _renewalFrequency = 'daily';

  bool get _isEditing => widget.ride != null;

  static const List<String> _renewalFrequencies = [
    'daily',
    'weekdays',
    'weekly',
  ];

  @override
  void initState() {
    super.initState();
    _rideNameController = TextEditingController(
      text: widget.ride?.rideName ?? '',
    );
    _bookingStartTimeController = TextEditingController(
      text: widget.ride?.bookingStartTime ?? '06:00',
    );
    _renewEnabled = widget.ride?.renewEnabled ?? false;
    final renewalFrequency = widget.ride?.renewalFrequency ?? 'daily';
    _renewalFrequency = _renewalFrequencies.contains(renewalFrequency)
        ? renewalFrequency
        : 'daily';
  }

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
      final existingRide = widget.ride;
      final ride = Ride(
        id: existingRide?.id ?? '',
        driverId: existingRide?.driverId ?? currentUser.uid,
        vehicleId: existingRide?.vehicleId ?? widget.vehicle.id,
        companyId: existingRide?.companyId ?? companyId,
        rideName: rideName,
        bookingStartTime: bookingStartTime,
        status: existingRide?.status ?? 'scheduled',
        renewEnabled: _renewEnabled,
        renewalFrequency: _renewalFrequency,
        bookingOpenAt: existingRide?.bookingOpenAt,
        roadDescription: existingRide?.roadDescription ?? '',
        currentLocation: existingRide?.currentLocation ?? '',
        lastLatitude: existingRide?.lastLatitude,
        lastLongitude: existingRide?.lastLongitude,
        lastAccuracy: existingRide?.lastAccuracy,
        lastSpeed: existingRide?.lastSpeed,
        createdAt: existingRide?.createdAt ?? DateTime.now(),
        startedAt: existingRide?.startedAt,
        endedAt: existingRide?.endedAt,
      );

      if (_isEditing) {
        await _firestoreService.updateRide(ride);
      } else {
        await _firestoreService.addRide(ride);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Ride updated successfully'
                : 'Ride created successfully',
          ),
        ),
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

  Future<void> _pickBookingStartTime() async {
    final currentValue = _bookingStartTimeController.text.trim();
    final parts = currentValue.split(':');
    final initialTime = TimeOfDay(
      hour: parts.isNotEmpty ? int.tryParse(parts[0]) ?? 6 : 6,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (selectedTime == null) return;

    _bookingStartTimeController.text =
        '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
  }

  String _renewalLabel(String frequency) {
    return switch (frequency) {
      'weekdays' => 'Weekdays',
      'weekly' => 'Weekly',
      _ => 'Daily',
    };
  }

  @override
  Widget build(BuildContext context) {
    final passengerSeats = widget.vehicle.seatCapacity > 0
        ? widget.vehicle.seatCapacity - 1
        : 0;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Ride' : 'Add Ride')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
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
                            widget.vehicle.vehicleNumber,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            '${widget.vehicle.vehicleType} • $passengerSeats passenger seats',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Ride details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _rideNameController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Ride Name',
                        hintText: 'e.g. Morning ride',
                        prefixIcon: const Icon(Icons.route),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _bookingStartTimeController,
                      readOnly: true,
                      onTap: _pickBookingStartTime,
                      decoration: InputDecoration(
                        labelText: 'Booking Start Time',
                        hintText: 'e.g. 06:00',
                        prefixIcon: const Icon(Icons.schedule),
                        suffixIcon: const Icon(Icons.expand_more),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.autorenew),
                      title: const Text('Auto renew ride'),
                      subtitle: Text(
                        _renewEnabled
                            ? _renewalLabel(_renewalFrequency)
                            : 'Off',
                      ),
                      value: _renewEnabled,
                      onChanged: (value) {
                        setState(() {
                          _renewEnabled = value;
                        });
                      },
                    ),
                    if (_renewEnabled) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final frequency in _renewalFrequencies)
                            ChoiceChip(
                              label: Text(_renewalLabel(frequency)),
                              selected: _renewalFrequency == frequency,
                              onSelected: (_) {
                                setState(() {
                                  _renewalFrequency = frequency;
                                });
                              },
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _saveRide,
                icon: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_isEditing ? Icons.save : Icons.add),
                label: Text(_isEditing ? 'Save Changes' : 'Create Ride'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
