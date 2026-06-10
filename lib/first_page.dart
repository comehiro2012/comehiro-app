import 'package:flutter/material.dart';
import 'time_select_page.dart';

class FirstPage extends StatelessWidget {
  const FirstPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            const Center(
              child: Text(
                '予約にあたっての注意事項',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 80),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('・'),
                Expanded(child: Text('ご予約は前日の15時までにお願いします。')),
              ],
            ),
            const SizedBox(height: 10),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('・'),
                Expanded(child: Text('受取時間は10:00から15:00までとなります。')),
              ],
            ),
            const SizedBox(height: 10),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('・'),
                Expanded(
                  child: Text('平日はお作りできない商品があります。（予約できない商品は選択できないようになっています。）'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('・'),
                Expanded(
                  child: Text(
                    '※原材料の仕入れ状況等によりご予約商品がご用意できないことがあります。その場合、メールやお電話で連絡させていただきます。',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('・'),
                Expanded(
                  child: Text(
                    'ご予約のキャンセルは前日15:00までに電話にてお願いします。当日のキャンセルは100%のキャンセル料が発生します。',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () async {
                  // 15時ルールに基づく最短日の計算
                  final now = DateTime.now();
                  DateTime minDate;
                  if (now.hour >= 15) {
                    minDate = DateTime(now.year, now.month, now.day + 2);
                  } else {
                    minDate = DateTime(now.year, now.month, now.day + 1);
                  }

                  // カレンダーを表示
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: minDate,
                    firstDate: minDate,
                    lastDate: now.add(const Duration(days: 30)),
                    locale: const Locale('ja', 'JP'),
                    selectableDayPredicate: (DateTime day) {
                      // 定休日（月・火）とGW休暇（2026/5/4〜5/8）を除外
                      if (day.weekday == DateTime.monday ||
                          day.weekday == DateTime.tuesday)
                        return false;
                      if (day.isAfter(DateTime(2026, 5, 3)) &&
                          day.isBefore(DateTime(2026, 5, 9)))
                        return false;
                      return true;
                    },
                  );

                  // --- ここから修正部分 ---
                  if (pickedDate != null) {
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // ↓ ProductSelectPage ではなく TimeSelectPage に飛ばす
                        builder: (context) => TimeSelectPage(
                          selectedDate: pickedDate, // 選んだ日付を渡す
                        ),
                      ),
                    );
                  }
                  // --- ここまで ---
                },
                child: const Text('同意して日時選択へ', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
