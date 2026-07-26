class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.weekdayLimit,
    required this.weekendLimit,
    required this.allergies,
  });

  factory Product.fromLegacyMap(Map<String, dynamic> source) => Product(
    id: source['name'] as String,
    name: source['name'] as String,
    category: source['category'] as String,
    price: source['price'] as int,
    weekdayLimit: source['limit_weekday'] as int? ?? 0,
    weekendLimit: source['limit_weekend'] as int? ?? 0,
    allergies: List<String>.from(source['allergies'] as List? ?? const []),
  );

  final String id;
  final String name;
  final String category;
  final int price;
  final int weekdayLimit;
  final int weekendLimit;
  final List<String> allergies;

  int limitFor(DateTime date) =>
      date.weekday == DateTime.saturday || date.weekday == DateTime.sunday
      ? weekendLimit
      : weekdayLimit;
}
