import 'package:flutter/material.dart';
import '../theme.dart';

class VehicleSelector extends StatelessWidget {
  final String selected;
  final Function(String) onChanged;

  const VehicleSelector({
    Key? key,
    required this.selected,
    required this.onChanged,
  }) : super(key: key);

  final List<Map<String, dynamic>> _vehicles = const [
    {'type': 'سيدان', 'icon': Icons.directions_car},
    {'type': 'SUV', 'icon': Icons.car_rental},
    {'type': 'دفع رباعي', 'icon': Icons.agriculture},
    {'type': 'شاحنة صغيرة', 'icon': Icons.local_shipping},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('نوع المركبة', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _vehicles.map((vehicle) {
            final isSelected = vehicle['type'] == selected;
            return GestureDetector(
              onTap: () => onChanged(vehicle['type']),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      vehicle['icon'],
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      vehicle['type'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
