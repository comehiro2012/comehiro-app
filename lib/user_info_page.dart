import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/utils/date_extensions.dart';
import 'models/reservation.dart';
import 'order_confirm_page.dart';

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({
    super.key,
    required this.pickupDateTime,
    required this.items,
  });
  final DateTime pickupDateTime;
  final List<ReservationItem> items;

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();

  int get _total =>
      widget.items.fold(0, (total, item) => total + item.subtotal);

  @override
  void initState() {
    super.initState();
    _loadSavedInfo();
  }

  Future<void> _loadSavedInfo() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _nameController.text = preferences.getString('user_name') ?? '';
      _phoneController.text = preferences.getString('user_phone') ?? '';
      _emailController.text = preferences.getString('user_email') ?? '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _continueToConfirmation() {
    if (!_formKey.currentState!.validate()) return;
    final draft = ReservationDraft(
      pickupDateTime: widget.pickupDateTime,
      customerName: _nameController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      customerEmail: _emailController.text.trim(),
      notes: _notesController.text.trim(),
      items: widget.items,
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderConfirmPage(reservation: draft)),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('お客様情報の入力')),
    body: Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _PickupSummary(pickupDateTime: widget.pickupDateTime),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'お名前（苗字のみ、ニックネーム可）',
                icon: Icon(Icons.person),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'お名前を入力してください。'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'お電話番号',
                icon: Icon(Icons.phone),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? '電話番号を入力してください。'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'メールアドレス',
                icon: Icon(Icons.email),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                    ? null
                    : '正しいメールアドレスを入力してください。';
              },
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '備考欄（ご要望などがあればご記入ください）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '合計金額: ¥$_total',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _continueToConfirmation,
                child: const Text('確認画面へ進む'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PickupSummary extends StatelessWidget {
  const _PickupSummary({required this.pickupDateTime});
  final DateTime pickupDateTime;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.orange.shade50,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      'お受取日時：${pickupDateTime.japaneseDate} ${pickupDateTime.hhmm} 頃',
      textAlign: TextAlign.center,
      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
    ),
  );
}
