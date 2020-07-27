DateTime modifyDateTime(DateTime dateTime,
    {int year, int month, int day, int hour, int minute, int second, int millisecond, int microsecond}) {
  return DateTime(
    year ?? dateTime.year,
    month ?? dateTime.month,
    day ?? dateTime.day,
    hour ?? dateTime.hour,
    minute ?? dateTime.minute,
    second ?? dateTime.second,
    millisecond ?? dateTime.millisecond,
    microsecond ?? dateTime.microsecond,
  );
}
