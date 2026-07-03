import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'product_data.dart'; // パンの一覧データ（allProducts）を参照するためにインポート

/// ==========================================
/// 1. お客様情報の入力画面（UserInfoPage）
/// ==========================================
class UserInfoPage extends StatefulWidget {
  final Map<String, int> orderCount;
  final int totalAmount;
  final DateTime selectedDate;

  const UserInfoPage({
    super.key,
    required this.orderCount,
    required this.totalAmount,
    required this.selectedDate,
  });

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();

  final List<String> _weekDays = ['日', '月', '火', '水', '木', '金', '土'];

  @override
  void initState() {
    super.initState();
    _loadSavedInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('user_name') ?? '';
      _phoneController.text = prefs.getString('user_phone') ?? '';
      _emailController.text = prefs.getString('user_email') ?? '';
    });
  }

  // 💡 入力チェックをして確認画面へ進む
  void _navigateToConfirmPage() {
    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _emailController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('すべてのお客様情報を入力してください')));
      return;
    }

    // 💡 完全に新しい「確認画面」へデータを渡して移動する
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OrderConfirmPage(
          orderCount: widget.orderCount,
          totalAmount: widget.totalAmount,
          selectedDate: widget.selectedDate,
          userName: _nameController.text.trim(),
          userPhone: _phoneController.text.trim(),
          userEmail: _emailController.text.trim(),
          notes: _notesController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String displayTime = DateFormat('HH:mm').format(widget.selectedDate);
    final String displayDayName =
        _weekDays[widget.selectedDate.toLocal().weekday % 7];

    return Scaffold(
      appBar: AppBar(title: const Text('お客様情報の入力')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'お受取日時：${widget.selectedDate.year}年${widget.selectedDate.month}月${widget.selectedDate.day}日（$displayDayName） $displayTime 頃',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.brown,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'お名前（苗字のみ、ニックネーム可）',
                hintText: '例：コメヒロ',
                icon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'お電話番号',
                icon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'メールアドレス',
                icon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: '備考欄（ご要望などがあればご記入ください）',
                  hintText: '',
                  alignLabelWithHint: true,
                  icon: const Icon(Icons.rate_review_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            Text(
              '合計金額: ¥${widget.totalAmount}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: _navigateToConfirmPage, // 💡 次の画面へ進む処理に変更
                child: const Text(
                  '確認画面へ進む',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ==========================================
/// 2. 新着追加：注文内容の最終確認画面（OrderConfirmPage）
/// ==========================================
class OrderConfirmPage extends StatefulWidget {
  final Map<String, int> orderCount;
  final int totalAmount;
  final DateTime selectedDate;
  final String userName;
  final String userPhone;
  final String userEmail;
  final String notes;

  const OrderConfirmPage({
    super.key,
    required this.orderCount,
    required this.totalAmount,
    required this.selectedDate,
    required this.userName,
    required this.userPhone,
    required this.userEmail,
    required this.notes,
  });

  @override
  State<OrderConfirmPage> createState() => _OrderConfirmPageState();
}

class _OrderConfirmPageState extends State<OrderConfirmPage> {
  bool _isSending = false;
  final List<String> _weekDays = ['日', '月', '火', '水', '木', '金', '土'];

  Future<void> _sendOrderToFirebase() async {
    setState(() => _isSending = true);

    try {
      // 次回入力のためにスマホへ保存
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', widget.userName);
      await prefs.setString('user_phone', widget.userPhone);
      await prefs.setString('user_email', widget.userEmail);

      final notesText = widget.notes.isEmpty ? 'なし' : widget.notes;

      // お客様向けメール用の「商品内訳テキスト（HTML）」
      String orderItemsHtml = '';
      widget.orderCount.forEach((productName, count) {
        if (count > 0) {
          orderItemsHtml +=
              '<li style="margin-bottom: 8px; list-style: none; border-bottom: 1px dashed #eee; padding-bottom: 8px; display: flex; justify-content: space-between;">'
              '<span>$productName</span>'
              '<span style="font-weight: bold;">$count 個</span>'
              '</li>';
        }
      });

      // 受取日時の文字列生成
      final localDateTime = widget.selectedDate.toLocal();
      final dayName = _weekDays[localDateTime.weekday % 7];
      final pickupDateStr =
          "${localDateTime.year}年${localDateTime.month}月${localDateTime.day}日（$dayName）";
      final pickupTimeStr = DateFormat('HH:mm').format(localDateTime);

      // コレクション 'mail' に保存して送信をトリガー
      await FirebaseFirestore.instance.collection('mail').add({
        'to': widget.userEmail,
        'message': {
          'subject': '【こめひろ】店頭受取のご予約を承りました',
          'html':
              '''
          <div style="font-family: 'Helvetica Neue', Arial, 'Hiragino Kaku Gothic ProN', Meiryo, sans-serif; color: #444444; max-width: 560px; margin: 0 auto; padding: 20px 10px;">
            <div style="text-align: center; padding-bottom: 24px; border-bottom: 2px solid #6d4c41;">
              <h2 style="margin: 0; font-size: 18px; color: #5d4037; letter-spacing: 1px;">ご予約ありがとうございます</h2>
              <p style="margin: 8px 0 0 0; font-size: 13px; color: #777777;">店頭受取のご予約を以下の内容で承りました。</p>
            </div>
            <div style="padding-top: 24px;">
              <p style="font-size: 14px; margin-bottom: 20px;">${widget.userName} 様</p>
              <p style="font-size: 14px; line-height: 1.6; color: #555555;">いつもこめひろをご利用いただきありがとうございます。<br>当日のご来店を心よりお待ちしております。</p>
              
              <h3 style="font-size: 14px; font-weight: bold; color: #5d4037; border-left: 3px solid #8d6e63; padding-left: 8px; margin: 28px 0 12px 0;">■ ご予約日時</h3>
              <div style="background-color: #fafafa; border-radius: 6px; padding: 16px; border: 1px solid #eeeeee;">
                <table style="width: 100%; font-size: 14px; border-collapse: collapse;">
                  <tr>
                    <td style="width: 70px; padding: 4px 0; color: #777777;">受取日</td>
                    <td style="padding: 4px 0; font-weight: bold; color: #333333;">$pickupDateStr</td>
                  </tr>
                  <tr>
                    <td style="padding: 4px 0; color: #777777;">時間枠</td>
                    <td style="padding: 4px 0; font-weight: bold; color: #d84315; font-size: 15px;">$pickupTimeStr 頃</td>
                  </tr>
                </table>
              </div>

              <h3 style="font-size: 14px; font-weight: bold; color: #5d4037; border-left: 3px solid #8d6e63; padding-left: 8px; margin: 28px 0 12px 0;">■ お受取り商品内訳</h3>
              <div style="padding: 4px 8px;">
                <ul style="padding: 0; margin: 0; font-size: 14px; color: #444444;">
                  $orderItemsHtml
                </ul>
                <div style="text-align: right; margin-top: 12px; font-size: 15px; font-weight: bold; color: #333333;">
                  合計金額: <span style="font-size: 18px; color: #d84315;">¥${widget.totalAmount}</span>
                </div>
              </div>

              <h3 style="font-size: 14px; font-weight: bold; color: #5d4037; border-left: 3px solid #8d6e63; padding-left: 8px; margin: 28px 0 12px 0;">■ 備考欄（ご要望）</h3>
              <div style="background-color: #fdfdfd; padding: 12px; border-radius: 6px; white-space: pre-wrap; font-size: 13px; border: 1px solid #eeeeee; color: #666666; line-height: 1.5;">${notesText.replaceAll('\n', '<br>')}</div>
              
              <div style="margin-top: 40px; padding-top: 20px; border-top: 1px solid #eeeeee; text-align: center;">
                <p style="font-size: 12px; color: #888888; margin: 0; line-height: 1.6;">
                  お気をつけてお越しくださいませ。<br>
                  <span style="font-weight: bold; color: #5d4037; font-size: 13px;">米粉パン専門店 こめひろ</span>
                </p>
              </div>
            </div>
          </div>
          ''',
        },
        'orderDetail': {
          'userName': widget.userName,
          'userPhone': widget.userPhone,
          'userEmail': widget.userEmail,
          'totalPrice': widget.totalAmount,
          'orderCount': widget.orderCount,
          'pickupDate': Timestamp.fromDate(widget.selectedDate),
          'notes': notesText,
          'createdAt': FieldValue.serverTimestamp(),
        },
      });

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('予約完了'),
          content: Text('${widget.userEmail} 宛に確認メールを送信しました。'),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('送信エラー: $e')));
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String displayTime = DateFormat('HH:mm').format(widget.selectedDate);
    final String displayDayName =
        _weekDays[widget.selectedDate.toLocal().weekday % 7];

    return Scaffold(
      appBar: AppBar(title: const Text('ご予約内容の確認')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'まだ予約は確定していません。\n内容をご確認の上、「予約を確定する」を押してください。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 25),

            // 🛠️ 1. 受取日時
            const Text(
              '■ お受取日時',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            const SizedBox(height: 5),
            Card(
              color: Colors.orange.shade50,
              child: ListTile(
                title: Text(
                  '${widget.selectedDate.year}年${widget.selectedDate.month}月${widget.selectedDate.day}日（$displayDayName） $displayTime 頃',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // 🛠️ 2. お客様情報
            const Text(
              '■ お客様情報',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            const SizedBox(height: 5),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Table(
                  columnWidths: const {0: FixedColumnWidth(90)},
                  children: [
                    TableRow(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'お名前:',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '${widget.userName} 様',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'お電話番号:',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(widget.userPhone),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'メール:',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(widget.userEmail),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // 🛠️ 3. 注文商品内訳
            const Text(
              '■ ご予約商品',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            const SizedBox(height: 5),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    ...widget.orderCount.entries.where((e) => e.value > 0).map((
                      entry,
                    ) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key),
                            Text(
                              '${entry.value} 個',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '合計金額',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '¥${widget.totalAmount}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // 🛠️ 4. 備考欄
            const Text(
              '■ 備考欄（ご要望）',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            const SizedBox(height: 5),
            Card(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                child: Text(
                  widget.notes.isEmpty ? 'なし' : widget.notes,
                  style: const TextStyle(color: Colors.black87),
                ),
              ),
            ),

            const SizedBox(height: 35),

            // 確定ボタン
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600, // 💡 確定を促すために緑色に変更
                  foregroundColor: Colors.white,
                ),
                onPressed: _isSending ? null : _sendOrderToFirebase,
                child: _isSending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'この内容で予約を確定する',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 15),
            // 戻るボタン
            SizedBox(
              width: double.infinity,
              height: 45,
              child: OutlinedButton(
                onPressed: _isSending
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text('入力画面に戻って修正する'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
