import 'package:flutter_test/flutter_test.dart';
import 'package:learning_flutter_base/core/reservation/reservation_validator.dart';

void main() {
  group('ReservationValidator', () {
    test('締切前は翌営業日を予約できる', () {
      final now = DateTime(2026, 8, 5, 14);

      expect(
        ReservationValidator.firstReservableDate(now),
        DateTime(2026, 8, 6),
      );
    });

    test('15時以降は翌々日以降の営業日から予約できる', () {
      final now = DateTime(2026, 8, 5, 15);

      expect(
        ReservationValidator.firstReservableDate(now),
        DateTime(2026, 8, 7),
      );
    });

    test('定休日と休業日は選択できない', () {
      final now = DateTime(2026, 8, 1, 10);

      expect(
        ReservationValidator.canSelect(DateTime(2026, 8, 3), now),
        isFalse,
      );
      expect(
        ReservationValidator.canSelect(DateTime(2026, 8, 12), now),
        isFalse,
      );
    });
  });
}
