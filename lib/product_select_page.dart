import 'package:flutter/material.dart';

import 'core/reservation/reservation_validator.dart';
import 'core/utils/date_extensions.dart';
import 'data/product_catalog.dart';
import 'models/product.dart';
import 'models/reservation.dart';
import 'user_info_page.dart';

class ProductSelectPage extends StatefulWidget {
  const ProductSelectPage({super.key, required this.initialDate});
  final DateTime initialDate;

  @override
  State<ProductSelectPage> createState() => _ProductSelectPageState();
}

class _ProductSelectPageState extends State<ProductSelectPage> {
  late DateTime _pickupDateTime;
  final Map<String, int> _quantities = {};
  static const _categories = ['食パン', '菓子パン', '調理パン'];

  @override
  void initState() {
    super.initState();
    _pickupDateTime = widget.initialDate;
  }

  List<ReservationItem> get _items => productCatalog
      .where((product) => (_quantities[product.id] ?? 0) > 0)
      .map(
        (product) => ReservationItem(
          productId: product.id,
          name: product.name,
          unitPrice: product.price,
          quantity: _quantities[product.id]!,
        ),
      )
      .toList(growable: false);

  int get _totalAmount =>
      _items.fold(0, (total, item) => total + item.subtotal);
  int get _totalItemCount =>
      _items.fold(0, (total, item) => total + item.quantity);

  Future<void> _changeDate() async {
    final now = DateTime.now();
    final firstDate = ReservationValidator.firstReservableDate(now);
    final initialDate = ReservationValidator.canSelect(_pickupDateTime, now)
        ? _pickupDateTime
        : firstDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: ReservationValidator.lastReservableDate(now),
      locale: const Locale('ja', 'JP'),
      selectableDayPredicate: (day) => ReservationValidator.canSelect(day, now),
    );
    if (picked == null) return;
    setState(() {
      _pickupDateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _pickupDateTime.hour,
      );
      _quantities.clear();
    });
  }

  void _goToCustomerInfo() {
    final validation = ReservationValidator.validate(
      _pickupDateTime,
      DateTime.now(),
    );
    if (!validation.isValid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validation.message!)));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            UserInfoPage(pickupDateTime: _pickupDateTime, items: _items),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: _categories.length,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('予約商品を選択して下さい'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _changeDate,
          ),
        ],
        bottom: const TabBar(
          tabs: [
            Tab(text: '食パン'),
            Tab(text: '菓子パン'),
            Tab(text: '調理パン'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.orange.shade50,
            padding: const EdgeInsets.all(10),
            child: Text(
              '予約日：${_pickupDateTime.japaneseDate}（${_pickupDateTime.hhmm} 頃）',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: TabBarView(children: _categories.map(_productList).toList()),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('合計 $_totalItemCount 点'),
                  Text(
                    '¥$_totalAmount（税込）',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: _items.isEmpty ? null : _goToCustomerInfo,
                child: const Text('注文内容の入力へ'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _productList(String category) {
    final products = productCatalog
        .where(
          (product) =>
              product.category == category &&
              product.limitFor(_pickupDateTime) > 0,
        )
        .toList();
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (_, index) => _productTile(products[index]),
    );
  }

  Widget _productTile(Product product) {
    final quantity = _quantities[product.id] ?? 0;
    final limit = product.limitFor(_pickupDateTime);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${product.price}円 / 上限: $limit個'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: quantity == 0
                  ? null
                  : () =>
                        setState(() => _quantities[product.id] = quantity - 1),
            ),
            Text(
              '$quantity',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: quantity >= limit
                  ? null
                  : () =>
                        setState(() => _quantities[product.id] = quantity + 1),
            ),
          ],
        ),
      ),
    );
  }
}
