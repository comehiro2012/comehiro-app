import 'package:flutter/material.dart';

/// 店頭予約に関するルールの唯一の設定場所です。
class ReservationRules {
  ReservationRules._();

  static const closedWeekdays = {DateTime.monday, DateTime.tuesday};
  static const cutoffHour = 15;
  static const bookingWindowDays = 30;

  /// 両端を含む休業期間。新しい休業日はここへ追加します。
  static final holidayPeriods = <DateTimeRange>[
    DateTimeRange(start: DateTime(2026, 8, 10), end: DateTime(2026, 8, 14)),
  ];
}
