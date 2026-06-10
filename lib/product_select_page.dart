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

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
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
          _selectedDate.hour,
          _selectedDate.minute,
        );
        orderCount.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ruleText を削除してすっきりさせました
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
          // ★ タブのデザインを変更して目立たせました
          bottom: const TabBar(
            indicatorColor: Colors.orange,
            indicatorWeight: 4.0, // 下線を太くして存在感アップ
            labelColor: Colors.black,
            labelStyle: TextStyle(
              fontSize: 16, // 文字サイズを大きく
              fontWeight: FontWeight.bold, // くっきり太字に
            ),
            unselectedLabelColor: Colors.black54, // 選択されていないタブを少し薄くしてメリハリを
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
                '予約日：${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}',
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

        // --- 💡 ここから追加 ---
        // 1. カレンダーで選択された日付（_selectedDate）が平日の月〜金（1〜5）かどうかを判定します
        final bool isWeekday =
            _selectedDate.weekday >= DateTime.monday &&
            _selectedDate.weekday <= DateTime.friday;

        // 2. 現在のデータの「平日上限数（limit_weekday）」を取得します（安全のためにデフォルトを0に設定）
        final int limitWeekday = item['limit_weekday'] ?? 0;

        // 3. 平日、かつ平日上限数が0（ハーフサイズなど）であれば、画面に表示しない（空っぽの要素を返す）
        if (isWeekday && limitWeekday == 0) {
          return const SizedBox.shrink(); // 高さをゼロにしてスペースも詰めちゃいます
        }
        // --- 💡 ここまで追加 ---

        // --- 1. ルール撤廃にともない、一律1個から注文可能に修正 ---
        const int minOrder = 1;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            // --- 2. 〇個からの補足テキストを削除し、スッキリさせました ---
            subtitle: Text('${item['price']}円 / 上限: $limit個'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: count == 0
                      ? null
                      : () => setState(() {
                          // マイナスを押した時はシンプルに1ずつ減らすロジックに修正
                          orderCount[name] = count - 1;
                        }), // 👈 ここから下が途切れていた部分の補完です
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
