import 'package:flutter/material.dart';

class SeatLayoutScreen extends StatefulWidget {
  final int seatCapacity;
  final List<Map<String, dynamic>> initialLayout;

  const SeatLayoutScreen({
    super.key,
    required this.seatCapacity,
    this.initialLayout = const [],
  });

  @override
  State<SeatLayoutScreen> createState() => _SeatLayoutScreenState();
}

class _SeatLayoutScreenState extends State<SeatLayoutScreen> {
  late List<_SeatRowConfig> _rows;

  int get _totalSeats => _rows.fold(0, (total, row) => total + row.seats);

  int get _remainingSeats => widget.seatCapacity - _totalSeats;

  @override
  void initState() {
    super.initState();
    _rows = widget.initialLayout.isEmpty
        ? _buildDefaultRows(widget.seatCapacity)
        : widget.initialLayout.map(_SeatRowConfig.fromMap).toList();
  }

  List<_SeatRowConfig> _buildDefaultRows(int capacity) {
    final rows = <_SeatRowConfig>[];
    var remaining = capacity;

    while (remaining > 0) {
      final seats = remaining >= 4 ? 4 : remaining;
      rows.add(_SeatRowConfig(seats: seats, aisleAfter: seats > 2 ? 2 : null));
      remaining -= seats;
    }

    return rows;
  }

  void _addRow() {
    if (_remainingSeats <= 0) return;

    setState(() {
      final seats = _remainingSeats >= 4 ? 4 : _remainingSeats;
      _rows.add(_SeatRowConfig(seats: seats, aisleAfter: seats > 2 ? 2 : null));
    });
  }

  void _saveLayout() {
    if (_totalSeats != widget.seatCapacity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _remainingSeats > 0
                ? 'Add $_remainingSeats more seats to match capacity'
                : 'Remove ${_remainingSeats.abs()} seats to match capacity',
          ),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      _rows.map((row) => row.toMap()).toList(growable: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _totalSeats == widget.seatCapacity;

    return Scaffold(
      appBar: AppBar(title: const Text('Seat Layout')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Capacity ${widget.seatCapacity}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isValid
                                ? 'Layout is ready'
                                : _remainingSeats > 0
                                ? '$_remainingSeats seats remaining'
                                : '${_remainingSeats.abs()} seats over capacity',
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _addRow,
                      icon: const Icon(Icons.add),
                      label: const Text('Row'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < _rows.length; index++)
              _SeatRowEditor(
                key: ValueKey(index),
                rowNumber: index + 1,
                row: _rows[index],
                canRemove: _rows.length > 1,
                onChanged: (row) {
                  setState(() {
                    _rows[index] = row;
                  });
                },
                onRemove: () {
                  setState(() {
                    _rows.removeAt(index);
                  });
                },
              ),
            const SizedBox(height: 12),
            _SeatLayoutPreview(rows: _rows),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Save Layout'),
                onPressed: _saveLayout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeatRowEditor extends StatelessWidget {
  final int rowNumber;
  final _SeatRowConfig row;
  final bool canRemove;
  final ValueChanged<_SeatRowConfig> onChanged;
  final VoidCallback onRemove;

  const _SeatRowEditor({
    super.key,
    required this.rowNumber,
    required this.row,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Row $rowNumber',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Remove row',
                  onPressed: canRemove ? onRemove : null,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  tooltip: 'Remove seat',
                  onPressed: row.seats > 1
                      ? () {
                          final aisleAfter = row.aisleAfter;
                          onChanged(
                            row.copyWith(
                              seats: row.seats - 1,
                              aisleAfter:
                                  aisleAfter != null &&
                                      aisleAfter >= row.seats - 1
                                  ? null
                                  : aisleAfter,
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 92,
                  child: Center(
                    child: Text(
                      '${row.seats} seats',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Add seat',
                  onPressed: () =>
                      onChanged(row.copyWith(seats: row.seats + 1)),
                  icon: const Icon(Icons.add),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue: row.aisleAfter,
                    decoration: const InputDecoration(
                      labelText: 'Aisle',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('No aisle'),
                      ),
                      for (var i = 1; i < row.seats; i++)
                        DropdownMenuItem<int?>(
                          value: i,
                          child: Text('After $i'),
                        ),
                    ],
                    onChanged: (value) {
                      onChanged(row.copyWith(aisleAfter: value));
                    },
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

class _SeatLayoutPreview extends StatelessWidget {
  final List<_SeatRowConfig> rows;

  const _SeatLayoutPreview({required this.rows});

  @override
  Widget build(BuildContext context) {
    var seatNumber = 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Preview', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            for (final row in rows) ...[
              Row(
                children: [
                  for (var i = 1; i <= row.seats; i++) ...[
                    if (row.aisleAfter == i - 1) const SizedBox(width: 20),
                    Expanded(
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black12),
                        ),
                        alignment: Alignment.center,
                        child: Text('${seatNumber++}'),
                      ),
                    ),
                    if (i != row.seats) const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _SeatRowConfig {
  final int seats;
  final int? aisleAfter;

  const _SeatRowConfig({required this.seats, this.aisleAfter});

  factory _SeatRowConfig.fromMap(Map<String, dynamic> map) {
    return _SeatRowConfig(
      seats: map['seats'] ?? 1,
      aisleAfter: map['aisleAfter'],
    );
  }

  _SeatRowConfig copyWith({int? seats, Object? aisleAfter = _sentinel}) {
    return _SeatRowConfig(
      seats: seats ?? this.seats,
      aisleAfter: identical(aisleAfter, _sentinel)
          ? this.aisleAfter
          : aisleAfter as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {'seats': seats, if (aisleAfter != null) 'aisleAfter': aisleAfter};
  }
}

const Object _sentinel = Object();
