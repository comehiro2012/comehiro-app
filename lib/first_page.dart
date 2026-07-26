import 'package:flutter/material.dart';

import 'core/reservation/reservation_validator.dart';
import 'time_select_page.dart';

class FirstPage extends StatelessWidget {
  const FirstPage({super.key});

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = ReservationValidator.firstReservableDate(now);
    final picked = await showDatePicker(
      context: context,
      initialDate: firstDate,
      firstDate: firstDate,
      lastDate: ReservationValidator.lastReservableDate(now),
      locale: const Locale('ja', 'JP'),
      selectableDayPredicate: (day) => ReservationValidator.canSelect(day, now),
    );
    if (picked == null || !context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TimeSelectPage(selectedDate: picked)),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 36),
            const Center(
              child: Text(
                '予約にあたっての注意事項',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 56),
            const _Notice('ご予約は前日の15時までにお願いします。'),
            const _Notice('受取時間は10:00から15:00までとなります。'),
            const _Notice('月曜・火曜は定休日です。'),
            const _Notice('平日はお作りできない商品があります。（予約できない商品は選択できないようになっています。）'),
            const _Notice(
              '原材料の仕入れ状況等により、ご予約商品がご用意できないことがあります。その場合、メールやお電話で連絡させていただきます。',
            ),
            const _Notice(
              'ご予約のキャンセルは前日15:00までに電話にてお願いします。当日のキャンセルは100%のキャンセル料が発生します。',
              color: Colors.red,
              bold: true,
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
                onPressed: () => _selectDate(context),
                child: const Text('同意して日時選択へ', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice(this.text, {this.color, this.bold = false});
  final String text;
  final Color? color;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('・'),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: bold ? FontWeight.bold : null,
            ),
          ),
        ),
      ],
    ),
  );
}
