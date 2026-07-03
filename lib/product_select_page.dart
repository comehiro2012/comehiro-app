import 'package:flutter/material.dart';
import 'product_data.dart';
import 'user_info_page.dart';

class ProductSelectPage extends StatefulWidget {
  final DateTime initialDate;
  final String selectedTime;

  const ProductSelectPage({
    super.key,
    required this.initialDate,
    required this.selectedTime,
  });

  @override
  State<ProductSelectPage> createState() => _ProductSelectPageState();
}

class _ProductSelectPageState extends State<ProductSelectPage> {
  late DateTime _selectedDate;
  final Map<String, int> orderCount = {};

  // 💡 ポップアップの表示終了日時（2026年7月20日まで表示）
  final DateTime noticeEndDate = DateTime(2026, 7, 20, 23, 59);

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;

    // 画面が表示された直後にお知らせを表示
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _showAnnouncement(context);
      }
    });
  }

  // 💡 文字だけで魅せる、洗練されたお知らせダイアログ
  void _showAnnouncement(BuildContext context) {
    if (DateTime.now().isBefore(noticeEndDate)) {
      showDialog(
        context: context,
        barrierDismissible: true, // 枠外をタップしても優しく閉じられるように
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent, // 現代的なフラットホワイトをキープ
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.fromLTRB(
              28,
              32,
              28,
              24,
            ), // 下部の余白を調整
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🏷️ 控えめかつ洗練された「NEW」のタグ
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.brown.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'NEW PRODUCT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.brown.shade700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 🍞 タイトル
                const Text(
                  'よもぎあんぱん新登場',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                // ✍️ 💡 商品説明文（ここをお好きな文章に自由に変更できます！）
                Text(
                  '風味豊かな国産のよもぎを練り込んだ米粉の生地で、瀬戸の藻塩あんを包みました。',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6, // 行間を広げてモダンな読みやすさに
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '¥195（税込）',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            // 💡 ボタンを右下にシンプルに1つだけ配置
            actionsPadding: const EdgeInsets.fromLTRB(0, 0, 16, 12),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  '閉じる',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  // 曜日ごとの上限数を取得するロジック
  int getCustomerLimit(Map<String, dynamic> item, DateTime selectedDate) {
    final bool isWeekend =
        selectedDate.weekday == DateTime.saturday ||
        selectedDate.weekday == DateTime.sunday;
    return isWeekend
        ? (item['limit_weekend'] ?? 0)
        : (item['limit_weekday'] ?? 0);
  }

  // 合計金額の計算
  int get totalAmount {
    int total = 0;
    orderCount.forEach((name, count) {
      final product = allProducts.firstWhere((p) => p['name'] == name);
      total += (product['price'] as int) * count;
    });
    return total;
  }

  // 合計点数の計算
  int get totalItemCount {
    int count = 0;
    orderCount.forEach((_, value) => count += value);
    return count;
  }

  // カレンダーで日付を変更する処理
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('ja', 'JP'),
      selectableDayPredicate: (DateTime day) {
        if (day.weekday == DateTime.monday || day.weekday == DateTime.tuesday) {
          return false;
        }
        if (day.isAfter(DateTime(2026, 5, 3)) &&
            day.isBefore(DateTime(2026, 5, 9))) {
          return false;
        }
        return true;
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          widget.initialDate.hour,
          widget.initialDate.minute,
        );
        orderCount.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      key: ValueKey(_selectedDate),
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('予約商品を選択して下さい'),
          backgroundColor: Colors.orange.shade100,
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: () => _selectDate(context),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.orange,
            indicatorWeight: 4.0,
            labelColor: Colors.black,
            labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            unselectedLabelColor: Colors.black54,
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
              padding: const EdgeInsets.all(8),
              color: Colors.orange.shade50,
              width: double.infinity,
              child: Text(
                '予約日：${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day} (${widget.selectedTime})',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildProductList('食パン'),
                  _buildProductList('菓子パン'),
                  _buildProductList('調理パン'),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('合計 $totalItemCount 点'),
                    Text(
                      '¥$totalAmount（税込）',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: totalItemCount > 0
                      ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserInfoPage(
                              orderCount: orderCount,
                              totalAmount: totalAmount,
                              selectedDate: _selectedDate,
                            ),
                          ),
                        )
                      : null,
                  child: const Text('注文内容の入力へ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductList(String categoryName) {
    final filteredProducts = allProducts
        .where((p) => p['category'] == categoryName)
        .toList();

    return ListView.builder(
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final item = filteredProducts[index];
        final String name = item['name'];
        final int count = orderCount[name] ?? 0;
        final int limit = getCustomerLimit(item, _selectedDate);

        final bool isWeekday =
            _selectedDate.weekday >= DateTime.monday &&
            _selectedDate.weekday <= DateTime.friday;

        final int limitWeekday = item['limit_weekday'] ?? 0;

        if (isWeekday && limitWeekday == 0) {
          return const SizedBox.shrink();
        }

        const int minOrder = 1;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${item['price']}円 / 上限: $limit個'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: count == 0
                      ? null
                      : () => setState(() {
                          orderCount[name] = count - 1;
                        }),
                ),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: count >= limit
                      ? null
                      : () => setState(() {
                          orderCount[name] = count == 0 ? minOrder : count + 1;
                        }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
