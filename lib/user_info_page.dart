import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'product_data.dart'; // パンの一覧データ（allProducts）を参照するためにインポート

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

  bool _isSending = false;

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

  // スマホに保存された情報を読み出す
  Future<void> _loadSavedInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('user_name') ?? '';
      _phoneController.text = prefs.getString('user_phone') ?? '';
      _emailController.text = prefs.getString('user_email') ?? '';
    });
  }

  // Firebaseに注文を保存し、メール送信をトリガーする
  Future<void> _sendOrderToFirebase() async {
    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _emailController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('すべてのお客様情報を入力してください')));
      return;
    }

    setState(() => _isSending = true);

    try {
      // スマホに情報を保存
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', _nameController.text);
      await prefs.setString('user_phone', _phoneController.text);
      await prefs.setString('user_email', _emailController.text);

      // 備考欄のテキストを取得
      final notesText = _notesController.text.trim().isEmpty
          ? 'なし'
          : _notesController.text.trim();

      // ★ お客様向けメール用の「商品内訳テキスト（HTML）」を生成するロジックを追加
      String orderItemsHtml = '';
      widget.orderCount.forEach((productName, count) {
        if (count > 0) {
          orderItemsHtml +=
              '<li style="margin-bottom: 4px;"><strong>$productName</strong> × $count個</li>';
        }
      });

      // 受取日の文字列
      final pickupDateStr =
          "${widget.selectedDate.year}/${widget.selectedDate.month}/${widget.selectedDate.day}";

      // コレクション 'mail' に保存
      await FirebaseFirestore.instance.collection('mail').add({
        'to': _emailController.text,
        'message': {
          'subject': '【こめひろ】ご予約ありがとうございます',
          'html':
              '''
            <p>${_nameController.text} 様</p>
            <p>この度はご予約いただきありがとうございます。以下の内容で承りました。</p>
            <hr>
            <p><strong>■ ご予約内容</strong></p>
            <ul>
              <li><strong>受取日:</strong> $pickupDateStr</li>
              <li><strong>合計金額:</strong> ¥${widget.totalAmount}</li>
              <li><strong>お電話番号:</strong> ${_phoneController.text}</li>
            </ul>
            <p><strong>■ お受取り商品内訳</strong></p>
            <ul style="background-color: #f8f9fa; padding: 12px 24px; border-radius: 4px; list-style-type: square; color: #333;">
              $orderItemsHtml
            </ul>
            <p><strong>■ 備考欄（ご要望）:</strong></p>
            <div style="background-color: #fff3cd; padding: 8px 12px; border-radius: 4px; white-space: pre-wrap;">${notesText.replaceAll('\n', '<br>')}</div>
            <hr>
            <p>ご来店を心よりお待ちしております。</p>
          ''',
        },
        'orderDetail': {
          'userName': _nameController.text,
          'userPhone': _phoneController.text,
          'userEmail': _emailController.text,
          'totalPrice': widget.totalAmount,
          'orderCount': widget
              .orderCount, // ★ ここを 'items' から 'orderCount' に修正（これで全メールシステムと連動します！）
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
          content: Text('${_emailController.text} 宛に確認メールを送信しました。'),
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
    return Scaffold(
      appBar: AppBar(title: const Text('お客様情報の入力')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'お名前（苗字のみ、ニックネーム可）',
                hintText: '例：コメヒロ、コメコちゃん',
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
                onPressed: _isSending ? null : _sendOrderToFirebase,
                child: _isSending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        '予約を確定する',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
