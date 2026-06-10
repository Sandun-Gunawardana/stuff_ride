import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stuff_ride/services/firestore_service.dart';

class PassengerDashboard extends StatefulWidget {
  final String vehicleId;
  final Map<String, dynamic> vehicleData;

  const PassengerDashboard({
    super.key,
    required this.vehicleId,
    required this.vehicleData,
  });

  @override
  State<PassengerDashboard> createState() => _PassengerDashboardState();
}

class _PassengerDashboardState extends State<PassengerDashboard> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int? _selectedSeat;
  bool _isBooking = false;

  int get _seatCapacity => widget.vehicleData['seatCapacity'] ?? 0;

  String get _vehicleType =>
      (widget.vehicleData['vehicleType'] ?? 'Vehicle').toString();

  int get _seatColumns {
    final type = _vehicleType.toLowerCase();
    if (type.contains('bus')) return 4;
    if (type.contains('van')) return 3;
    return 2;
  }

  Future<void> _bookSelectedSeat(Set<int> bookedSeats) async {
    final seatNumber = _selectedSeat;
    final passenger = _auth.currentUser;

    if (seatNumber == null ||
        passenger == null ||
        bookedSeats.contains(seatNumber)) {
      return;
    }

    setState(() {
      _isBooking = true;
    });

    try {
      await _firestoreService.bookVehicleSeat(
        vehicleId: widget.vehicleId,
        passengerId: passenger.uid,
        seatNumber: seatNumber,
      );

      if (!mounted) return;

      setState(() {
        _selectedSeat = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seat $seatNumber booked successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Passenger Dashboard')),
      body: SafeArea(
        child: StreamBuilder<Set<int>>(
          stream: _firestoreService.getBookedVehicleSeats(widget.vehicleId),
          builder: (context, snapshot) {
            final bookedSeats = snapshot.data ?? <int>{};
            final availableSeats = (_seatCapacity - bookedSeats.length).clamp(
              0,
              _seatCapacity,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _VehicleSummary(
                    vehicleNumber: widget.vehicleData['vehicleNumber'] ?? 'N/A',
                    vehicleType: _vehicleType,
                    color: widget.vehicleData['color'] ?? 'N/A',
                    availableSeats: availableSeats,
                    totalSeats: _seatCapacity,
                  ),
                  const SizedBox(height: 16),
                  _LiveLocationPanel(
                    stream: _firestoreService.getLatestVehicleLocation(
                      widget.vehicleId,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SeatLegend(),
                  const SizedBox(height: 12),
                  _VehicleSeatLayout(
                    capacity: _seatCapacity,
                    columns: _seatColumns,
                    bookedSeats: bookedSeats,
                    selectedSeat: _selectedSeat,
                    onSeatSelected: (seatNumber) {
                      setState(() {
                        _selectedSeat = seatNumber;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: _isBooking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.event_seat),
                      label: Text(
                        _selectedSeat == null
                            ? 'Select a seat'
                            : 'Book seat $_selectedSeat',
                      ),
                      onPressed: _selectedSeat == null || _isBooking
                          ? null
                          : () => _bookSelectedSeat(bookedSeats),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _VehicleSummary extends StatelessWidget {
  final String vehicleNumber;
  final String vehicleType;
  final String color;
  final int availableSeats;
  final int totalSeats;

  const _VehicleSummary({
    required this.vehicleNumber,
    required this.vehicleType,
    required this.color,
    required this.availableSeats,
    required this.totalSeats,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(radius: 28, child: Icon(Icons.directions_bus)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicleNumber,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text('$vehicleType • $color'),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$availableSeats',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('of $totalSeats seats'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveLocationPanel extends StatelessWidget {
  final Stream<dynamic> stream;

  const _LiveLocationPanel({required this.stream});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<dynamic>(
          stream: stream,
          builder: (context, snapshot) {
            final data = snapshot.data?.data() as Map<String, dynamic>?;
            final latitude = (data?['latitude'] as num?)?.toDouble();
            final longitude = (data?['longitude'] as num?)?.toDouble();
            final speed = (data?['speed'] as num?)?.toDouble();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on),
                    const SizedBox(width: 8),
                    Text(
                      'Live Location',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 132,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3EF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFB8D3C8)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(double.infinity, 132),
                        painter: _MapGridPainter(),
                      ),
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Color(0xFF1565C0),
                        child: Icon(Icons.directions_bus, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (latitude == null || longitude == null)
                  const Text('Waiting for the driver location update')
                else
                  Text(
                    'Lat ${latitude.toStringAsFixed(5)}, Lng ${longitude.toStringAsFixed(5)}'
                    '${speed == null ? '' : ' • ${speed.toStringAsFixed(0)} km/h'}',
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SeatLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _LegendItem(color: Color(0xFFE8F5E9), label: 'Available'),
        SizedBox(width: 14),
        _LegendItem(color: Color(0xFFBBDEFB), label: 'Selected'),
        SizedBox(width: 14),
        _LegendItem(color: Color(0xFFFFCDD2), label: 'Booked'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.black12),
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _VehicleSeatLayout extends StatelessWidget {
  final int capacity;
  final int columns;
  final Set<int> bookedSeats;
  final int? selectedSeat;
  final ValueChanged<int> onSeatSelected;

  const _VehicleSeatLayout({
    required this.capacity,
    required this.columns,
    required this.bookedSeats,
    required this.selectedSeat,
    required this.onSeatSelected,
  });

  @override
  Widget build(BuildContext context) {
    final rows = (capacity / columns).ceil();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Front',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 72,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black12),
                ),
                child: const Icon(Icons.radio_button_checked),
              ),
            ),
            const SizedBox(height: 16),
            for (var row = 0; row < rows; row++) ...[
              Row(
                children: [
                  for (var column = 0; column < columns; column++) ...[
                    if (column == (columns / 2).ceil())
                      const SizedBox(width: 18),
                    Expanded(
                      child: _SeatTile(
                        seatNumber: (row * columns) + column + 1,
                        isVisible: (row * columns) + column + 1 <= capacity,
                        isBooked: bookedSeats.contains(
                          (row * columns) + column + 1,
                        ),
                        isSelected:
                            selectedSeat == (row * columns) + column + 1,
                        onTap: onSeatSelected,
                      ),
                    ),
                    if (column != columns - 1) const SizedBox(width: 8),
                  ],
                ],
              ),
              if (row != rows - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _SeatTile extends StatelessWidget {
  final int seatNumber;
  final bool isVisible;
  final bool isBooked;
  final bool isSelected;
  final ValueChanged<int> onTap;

  const _SeatTile({
    required this.seatNumber,
    required this.isVisible,
    required this.isBooked,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox(height: 54);
    }

    final color = isBooked
        ? const Color(0xFFFFCDD2)
        : isSelected
        ? const Color(0xFFBBDEFB)
        : const Color(0xFFE8F5E9);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: isBooked ? null : () => onTap(seatNumber),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF1565C0) : Colors.black12,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_seat,
              color: isBooked ? Colors.red.shade700 : Colors.black87,
            ),
            Text(
              '$seatNumber',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFFCADFD6)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.2,
        size.width,
        size.height * 0.38,
      );

    canvas.drawPath(path, roadPaint);
    canvas.drawLine(
      Offset(size.width * 0.22, 0),
      Offset(size.width * 0.82, size.height),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
