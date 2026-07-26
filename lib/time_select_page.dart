import 'package:flutter/material.dart';

import 'core/reservation/reservation_validator.dart';
import 'product_select_page.dart';

class TimeSelectPage extends StatelessWidget {
  const TimeSelectPage({super.key, required this.selectedDate});
  final DateTime selectedDate;

  static const _startHours = [10, 11, 12, 13, 14];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('受取時間を選択')),
    body: ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _startHours.length,
      itemBuilder: (context, index) {
        final hour = _startHours[index];
        final label =
            '${hour.toString().padLeft(2, '0')}:00 〜 ${(hour + 1).toString().padLeft(2, '0')}:00';
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(label, textAlign: TextAlign.center),
            onTap: () {
              final validation = ReservationValidator.validate(
                selectedDate,
                DateTime.now(),
              );
              if (!validation.isValid) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(validation.message!)));
                return;
              }
              final pickup = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                hour,
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductSelectPage(initialDate: pickup),
                ),
              );
            },
          ),
        );
      },
    ),
  );
}
