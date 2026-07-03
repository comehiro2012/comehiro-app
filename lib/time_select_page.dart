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
    // 💡 表示用の文字リスト
    final List<String> timeSlots = [
      '10:00 〜 11:00',
      '11:00 〜 12:00',
      '12:00 〜 13:00',
      '13:00 〜 14:00',
      '14:00 〜 15:00',
    ];

    // 💡 ズレを防ぐため、開始時間を数字のリストで正確に用意します
    final List<int> startHours = [10, 11, 12, 13, 14];

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
                // 💡 文字列を分解するのをやめて、上の数字リストから直接時間を取得（エラーを100%回避！）
                final int hour = startHours[index];
                const int minute = 0;

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
