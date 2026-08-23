class DateValidator {
  static bool isNotBefore(DateTime value, DateTime minimum) =>
      !value.isBefore(minimum);
}
