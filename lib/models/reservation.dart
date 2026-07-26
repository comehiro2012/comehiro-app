class ReservationItem {
  const ReservationItem({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
  });

  final String productId;
  final String name;
  final int unitPrice;
  final int quantity;
  int get subtotal => unitPrice * quantity;

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'name': name,
    'unitPrice': unitPrice,
    'quantity': quantity,
    'subtotal': subtotal,
  };
}

class ReservationDraft {
  const ReservationDraft({
    required this.pickupDateTime,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.notes,
    required this.items,
  });

  final DateTime pickupDateTime;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String notes;
  final List<ReservationItem> items;
  int get totalAmount => items.fold(0, (total, item) => total + item.subtotal);

  Map<String, dynamic> toCallablePayload() => {
    // タイムゾーンの曖昧さを避けるため、受取日時は日本時間の各要素で送ります。
    'pickupYear': pickupDateTime.year,
    'pickupMonth': pickupDateTime.month,
    'pickupDay': pickupDateTime.day,
    'pickupHour': pickupDateTime.hour,
    'pickupMinute': pickupDateTime.minute,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'customerEmail': customerEmail,
    'notes': notes,
    'items': items.map((item) => item.toMap()).toList(),
  };
}
