import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/reservation/reservation_validator.dart';
import 'core/utils/date_extensions.dart';
import 'models/reservation.dart';
import 'services/reservation_repository.dart';

class OrderConfirmPage extends StatefulWidget {
  const OrderConfirmPage({super.key, required this.reservation});
  final ReservationDraft reservation;

  @override
  State<OrderConfirmPage> createState() => _OrderConfirmPageState();
}

class _OrderConfirmPageState extends State<OrderConfirmPage> {
  final _repository = ReservationRepository();
  bool _isSubmitting = false;

  Future<void> _submit() async {
    final validation = ReservationValidator.validate(
      widget.reservation.pickupDateTime,
      DateTime.now(),
    );
    if (!validation.isValid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validation.message!)));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final preferences = await SharedPreferences.getInstance();
      await Future.wait([
        preferences.setString('user_name', widget.reservation.customerName),
        preferences.setString('user_phone', widget.reservation.customerPhone),
        preferences.setString('user_email', widget.reservation.customerEmail),
      ]);
      await _repository.create(widget.reservation);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('予約完了'),
          content: Text('${widget.reservation.customerEmail} 宛に確認メールを送信しました。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on ReservationRepositoryException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('通信に失敗しました。時間をおいてもう一度お試しください。')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
          const SizedBox(height: 24),
          _Section(
            title: 'お受取日時',
            child: Text(
              '${widget.reservation.pickupDateTime.japaneseDate} ${widget.reservation.pickupDateTime.hhmm} 頃',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          _Section(
            title: 'お客様情報',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${widget.reservation.customerName} 様'),
                Text(widget.reservation.customerPhone),
                Text(widget.reservation.customerEmail),
              ],
            ),
          ),
          _Section(
            title: 'ご予約商品',
            child: Column(
              children: [
                ...widget.reservation.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text(item.name), Text('${item.quantity} 個')],
                    ),
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '合計金額',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '¥${widget.reservation.totalAmount}',
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
          _Section(
            title: '備考欄',
            child: Text(
              widget.reservation.notes.isEmpty
                  ? 'なし'
                  : widget.reservation.notes,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('この内容で予約を確定する'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : () => Navigator.pop(context),
              child: const Text('入力画面に戻って修正する'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '■ $title',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.brown,
          ),
        ),
        const SizedBox(height: 5),
        Card(
          child: Padding(padding: const EdgeInsets.all(12), child: child),
        ),
      ],
    ),
  );
}
