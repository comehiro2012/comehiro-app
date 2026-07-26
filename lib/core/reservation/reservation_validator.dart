import 'reservation_rules.dart';

class ReservationValidationResult {
  const ReservationValidationResult.valid() : message = null;
  const ReservationValidationResult.invalid(this.message);

  final String? message;
  bool get isValid => message == null;
}

/// 画面のカレンダーと確定処理で共通して使う営業日判定です。
class ReservationValidator {
  ReservationValidator._();

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool isHoliday(DateTime date) {
    final target = dateOnly(date);
    return ReservationRules.holidayPeriods.any((period) {
      final start = dateOnly(period.start);
      final end = dateOnly(period.end);
      return !target.isBefore(start) && !target.isAfter(end);
    });
  }

  static bool isBusinessDay(DateTime date) =>
      !ReservationRules.closedWeekdays.contains(date.weekday) &&
      !isHoliday(date);

  static DateTime nextBusinessDay(DateTime date) {
    var candidate = dateOnly(date);
    while (!isBusinessDay(candidate)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  static DateTime firstReservableDate(DateTime now) {
    final offset = now.hour >= ReservationRules.cutoffHour ? 2 : 1;
    return nextBusinessDay(dateOnly(now).add(Duration(days: offset)));
  }

  static DateTime lastReservableDate(DateTime now) => dateOnly(
    now,
  ).add(const Duration(days: ReservationRules.bookingWindowDays));

  static bool canSelect(DateTime date, DateTime now) {
    final target = dateOnly(date);
    return isBusinessDay(target) &&
        !target.isBefore(firstReservableDate(now)) &&
        !target.isAfter(lastReservableDate(now));
  }

  static ReservationValidationResult validate(DateTime date, DateTime now) {
    final target = dateOnly(date);
    if (ReservationRules.closedWeekdays.contains(target.weekday)) {
      return const ReservationValidationResult.invalid('月曜・火曜は定休日のため予約できません。');
    }
    if (isHoliday(target)) {
      return const ReservationValidationResult.invalid('この日は休業日のため予約できません。');
    }
    if (target.isBefore(firstReservableDate(now))) {
      return const ReservationValidationResult.invalid('予約は前日15時までにお願いします。');
    }
    if (target.isAfter(lastReservableDate(now))) {
      return const ReservationValidationResult.invalid('予約できるのは30日先までです。');
    }
    return const ReservationValidationResult.valid();
  }
}
