import 'package:flutter/material.dart';

class DayView extends StatefulWidget {
  final DateTime selectedDate;

  const DayView({super.key, required this.selectedDate});

  @override
  State<DayView> createState() => _DayViewState();
}

class _DayViewState extends State<DayView> {
  bool _showWarning = true;

  final List<Map<String, dynamic>> _cycles = [
    {'title': 'Cycle 1', 'startHour': 8, 'endHour': 10},
    {'title': 'Cycle 2', 'startHour': 12, 'endHour': 14},
    {'title': 'Cycle 3', 'startHour': 18, 'endHour': 20},
    {'title': 'Cycle 4', 'startHour': 22, 'endHour': 24},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_showWarning)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _warningBanner(
              onClose: () => setState(() => _showWarning = false),
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time Column
                Column(
                  children: List.generate(17, (i) {
                    final hour = 8 + i;
                    return SizedBox(
                      height: 60,
                      child: Text(
                        "${hour.toString().padLeft(2, '0')}:00",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    );
                  }),
                ),
                const SizedBox(width: 12),
                // Event Timeline
                Expanded(
                  child: SizedBox(
                    height: 17 * 60.0, // 1020px
                    child: Stack(
                      children: _cycles.map((cycle) {
                        final topOffset = (cycle['startHour'] - 8) * 60.0;
                        final height = (cycle['endHour'] - cycle['startHour']) * 60.0;

                        return Positioned(
                          top: topOffset,
                          left: 0,
                          right: 0,
                          height: height,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2F80ED),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                cycle['title'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _warningBanner({required VoidCallback onClose}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "Your baby's next cycle overlaps with feeding time. Adjust timing if needed.",
              style: TextStyle(fontSize: 14),
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }
}
