import 'package:intl/intl.dart';

/// Currency and date formatting for Kenyan users.
abstract final class Fmt {
  static final _whole = NumberFormat('#,##0', 'en_US');
  static final _cents = NumberFormat('#,##0.00', 'en_US');

  /// `KES 4,250` (or `KES 4,250.00` with [cents]).
  static String kes(num amount, {bool cents = false}) =>
      'KES ${(cents ? _cents : _whole).format(amount)}';

  /// `KSh 12,400` used by Oobli Goals copy.
  static String ksh(num amount) => 'KSh ${_whole.format(amount)}';

  /// `- KES 450` / `+ KES 1,500` for transaction rows.
  static String signedKes(num amount, {required bool outgoing, bool spaced = true}) =>
      '${outgoing ? '-' : '+'}${spaced ? ' ' : ''}${kes(amount)}';

  /// `KES 14.2k`, `KES 1.2M`.
  static String compactKes(num amount) {
    final a = amount.abs();
    if (a >= 1000000) return 'KES ${(amount / 1000000).toStringAsFixed(1)}M';
    if (a >= 1000) return 'KES ${(amount / 1000).toStringAsFixed(1)}k';
    return kes(amount);
  }

  static String number(num value) => _whole.format(value);

  static String percent(double ratio, {int digits = 0}) =>
      '${(ratio * 100).toStringAsFixed(digits)}%';

  static String time12(DateTime d) => DateFormat('hh:mm a').format(d);
  static String time24(DateTime d) => DateFormat('HH:mm').format(d);
  static String shortDate(DateTime d) => DateFormat('MMM dd').format(d);
  static String dayMonth(DateTime d) => DateFormat('dd MMM').format(d).toUpperCase();
  static String monthName(DateTime d) => DateFormat('MMMM').format(d);
  static String monthYear(DateTime d) => DateFormat('MMMM yyyy').format(d);
  static String monthShort(DateTime d) => DateFormat('MMM').format(d);
  static String monthShortYear(DateTime d) => DateFormat('MMM yyyy').format(d);
  static String monthKey(DateTime d) => DateFormat('yyyy-MM').format(d);
  static String weekdayName(DateTime d) => DateFormat('EEEE').format(d);
  static String weekdayLetter(DateTime d) => DateFormat('E').format(d).substring(0, 1);

  /// "Today", "Yesterday" or `10:45 AM`-style relative label for list rows.
  static String relativeDay(DateTime d, {DateTime? now}) {
    final today = _day(now ?? DateTime.now());
    final diff = today.difference(_day(d)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(d);
    return shortDate(d);
  }

  static String timeAgo(DateTime d, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return shortDate(d);
  }

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'O';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
}

extension DateOnly on DateTime {
  DateTime get dateOnly => DateTime(year, month, day);
  DateTime get monthStart => DateTime(year, month);
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}
