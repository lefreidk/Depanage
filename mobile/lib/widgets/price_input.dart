import 'package:flutter/material.dart';
import '../theme.dart';
import '../config.dart';

class PriceInput extends StatefulWidget {
  final double initialPrice;
  final Function(double) onChanged;

  const PriceInput({
    Key? key,
    required this.initialPrice,
    required this.onChanged,
  }) : super(key: key);

  @override
  _PriceInputState createState() => _PriceInputState();
}

class _PriceInputState extends State<PriceInput> {
  late double _price;

  @override
  void initState() {
    super.initState();
    _price = widget.initialPrice;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('السعر المقترح', style: TextStyle(fontWeight: FontWeight.bold)),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_price.round()} ${AppConfig.currency}',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Slider(
          value: _price,
          min: 1000,
          max: 20000,
          divisions: 38,
          activeColor: AppTheme.primary,
          inactiveColor: Colors.grey[300],
          label: '${_price.round()} ${AppConfig.currency}',
          onChanged: (value) {
            setState(() {
              _price = value;
            });
            widget.onChanged(_price);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('1000 ${AppConfig.currency}', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            Text('20000 ${AppConfig.currency}', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      ],
    );
  }
}
