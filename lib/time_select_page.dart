import 'package:flutter/material.dart';
import 'product_select_page.dart';

class TimeSelectPage extends StatelessWidget {
  final DateTime selectedDate; // 追加：日付を受け取る変数

  const TimeSelectPage({
    super.key,
    required this.selectedDate, // 追加：必須にする
  });

  @override
  Widget build(BuildContext context) {
    final List<String> timeSlots = [
      '10:00 〜 11:00',
      '11:00 〜 12:00',
      '12:00 〜 13:00',
      '13:00 〜 14:00',
      '14:00 〜 15:00',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('受取時間を選択')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: timeSlots.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(timeSlots[index], textAlign: TextAlign.center),

              onTap: () {
                // 文字列 '10:00 〜 11:00' から最初の '10' と '00' を取り出す
                final timePart = timeSlots[index].split(' 〜 ')[0]; // '10:00'
                final hour = int.parse(timePart.split(':')[0]); // 10
                final minute = int.parse(timePart.split(':')[1]); // 0

                // 元々の selectedDate（日付）に、選んだ時間をセットした新しい DateTime を作成
                final pickupDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  hour,
                  minute,
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductSelectPage(
                      // ここで「日付＋時間」が合体した pickupDateTime を渡す
                      initialDate: pickupDateTime,
                      selectedTime: timeSlots[index], // 表示用
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
