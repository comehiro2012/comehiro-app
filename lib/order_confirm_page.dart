import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderConfirmPage extends StatelessWidget {
  final Map<String, int> orderCount;
  final int totalAmount;
  final DateTime selectedDate;

  const OrderConfirmPage({
    super.key,
    required this.orderCount,
    required this.totalAmount,
    required this.selectedDate,
  });

  // --- クラスの中にメール送信の関数を配置します ---
  Future<void> _sendEmail(BuildContext context) async {
    String orderDetails = "";
    orderCount.forEach((name, count) {
      if (count > 0) {
        orderDetails += "・$name: $count個\n";
      }
    });

    // ここから下の書き方を修正します
    final String subject = "【パン予約】${selectedDate.month}/${selectedDate.day}受取";
    final String body =
        """
こめひろ様

以下の内容でパンの予約をお願いします。

【受取日】: ${selectedDate.year}年${selectedDate.month}月${selectedDate.day}日
【注文内容】:
$orderDetails
【合計金額】: ¥$totalAmount（税込）

---
※お名前とご連絡先を以下にご記入ください
お名前：
お電話番号：
"""; // ここまでをしっかり囲む

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'comehiro.2012@gmail.com',
      query:
          'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        throw 'メールアプリを起動できませんでした';
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('エラー: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedItems = orderCount.entries
        .where((entry) => entry.value > 0)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('注文内容の確認'),
        backgroundColor: Colors.orange.shade100,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Colors.orange.shade50,
            child: Text(
              'お受取日: ${selectedDate.year}年${selectedDate.month}月${selectedDate.day}日',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: selectedItems.length,
              itemBuilder: (context, index) {
                final item = selectedItems[index];
                return Column(
                  children: [
                    ListTile(
                      title: Text(
                        item.key,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Text(
                        '${item.value} 個',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('合計金額', style: TextStyle(fontSize: 18)),
                      Text(
                        '¥$totalAmount',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      // 修正ポイント：ここだけで完結させます
                      onPressed: () => _sendEmail(context),
                      child: const Text(
                        'この内容で予約メールを作成する',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
