import 'package:intl/intl.dart';

/// Date/size formatting in the user's profile locale (independent of UI language).
/// An intl-unknown locale must degrade to the default format, never throw.

String formatDateTime(DateTime? dt, String locale) {
  if (dt == null) return '';
  final local = dt.toLocal();
  try {
    return '${DateFormat.yMMMd(locale).format(local)} '
        '${DateFormat.Hm(locale).format(local)}';
  } on ArgumentError {
    return '${DateFormat.yMMMd().format(local)} '
        '${DateFormat.Hm().format(local)}';
  }
}

String formatDateShort(DateTime? dt, String locale) {
  if (dt == null) return '';
  final local = dt.toLocal();
  try {
    return DateFormat.yMd(locale).format(local);
  } on ArgumentError {
    return DateFormat.yMd().format(local);
  }
}

/// Compact numeric date + time (HH:mm), for the dense results list — parity with
/// web/desktop, which now show the time in the Date column.
String formatDateTimeShort(DateTime? dt, String locale) {
  if (dt == null) return '';
  final local = dt.toLocal();
  try {
    return '${DateFormat.yMd(locale).format(local)} '
        '${DateFormat.Hm(locale).format(local)}';
  } on ArgumentError {
    return '${DateFormat.yMd().format(local)} ${DateFormat.Hm().format(local)}';
  }
}

String formatCount(int n, String locale) {
  try {
    return NumberFormat.decimalPattern(locale).format(n);
  } on ArgumentError {
    return NumberFormat.decimalPattern().format(n);
  }
}

String formatSize(int bytes, String locale) {
  if (bytes <= 0) return '0 B';
  const units = <String>['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final pattern = unit == 0 ? '#,##0' : '#,##0.#';
  NumberFormat fmt;
  try {
    fmt = NumberFormat(pattern, locale);
  } on ArgumentError {
    fmt = NumberFormat(pattern);
  }
  return '${fmt.format(value)} ${units[unit]}';
}
