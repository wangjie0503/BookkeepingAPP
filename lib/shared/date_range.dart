class DateRange {
  DateRange({required this.start, required this.end})
    : assert(!end.isBefore(start));

  final DateTime start;
  final DateTime end;

  bool contains(DateTime value) =>
      !value.isBefore(start) && !value.isAfter(end);
}
