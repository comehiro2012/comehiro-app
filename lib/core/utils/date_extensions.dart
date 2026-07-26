extension JapaneseDateFormatting on DateTime {
  static const _weekdays = ['日', '月', '火', '水', '木', '金', '土'];
  String get japaneseWeekday => _weekdays[weekday % 7];
  String get japaneseDate => '$year年$month月$day日（$japaneseWeekday）';
  String get hhmm =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
