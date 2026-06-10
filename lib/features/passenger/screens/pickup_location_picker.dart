import 'package:flutter/material.dart';

class PickupLocation {
  final String label;
  final double latitude;
  final double longitude;

  const PickupLocation({
    required this.label,
    required this.latitude,
    required this.longitude,
  });
}

class PickupLocationPicker extends StatefulWidget {
  const PickupLocationPicker({super.key});

  @override
  State<PickupLocationPicker> createState() => _PickupLocationPickerState();
}

class _PickupLocationPickerState extends State<PickupLocationPicker> {
  final TextEditingController _labelController = TextEditingController();
  Offset _point = const Offset(0.5, 0.5);

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _save() {
    final label = _labelController.text.trim();
    if (label.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a pickup location name')),
      );
      return;
    }

    Navigator.pop(
      context,
      PickupLocation(
        label: label,
        latitude: 6.9271 + ((_point.dy - 0.5) * 0.08),
        longitude: 79.8612 + ((_point.dx - 0.5) * 0.08),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pickup Location')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Pickup place',
                hintText: 'e.g., Main gate, building A, bus halt',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1.15,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onTapDown: (details) {
                      setState(() {
                        _point = Offset(
                          (details.localPosition.dx / constraints.maxWidth)
                              .clamp(0.0, 1.0),
                          (details.localPosition.dy / constraints.maxHeight)
                              .clamp(0.0, 1.0),
                        );
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3EF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFB8D3C8)),
                      ),
                      child: Stack(
                        children: [
                          CustomPaint(
                            size: Size.infinite,
                            painter: _PickupMapPainter(),
                          ),
                          Positioned(
                            left: (_point.dx * constraints.maxWidth) - 18,
                            top: (_point.dy * constraints.maxHeight) - 36,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            const Text('Tap the map area to mark your pickup point.'),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Use Pickup Location'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickupMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFFCADFD6)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.18),
      Offset(size.width * 0.88, size.height * 0.82),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.68),
      Offset(size.width * 0.92, size.height * 0.42),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.08),
      Offset(size.width * 0.5, size.height * 0.92),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
