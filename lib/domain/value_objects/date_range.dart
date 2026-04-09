/// Inclusive financial period: [start] must not be after [end].
final class DateRange {
  DateRange({required this.start, required this.end}) {
    if (start.isAfter(end)) {
      throw ArgumentError.value(
        end,
        'end',
        'DateRange end must be on or after start',
      );
    }
  }

  final DateTime start;
  final DateTime end;

  bool contains(DateTime date) {
    return (date.isAtSameMomentAs(start) || date.isAfter(start)) &&
        (date.isAtSameMomentAs(end) || date.isBefore(end));
  }
}
