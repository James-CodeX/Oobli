import '../core/utils/formatters.dart';
import '../data/models/category.dart';
import '../data/models/transaction.dart';

/// A structured reading of a search like "boda last month" or
/// "netflix this year over 1000".
class SearchFilter {
  const SearchFilter({
    this.from,
    this.to,
    this.categories = const {},
    this.terms = const [],
    this.direction,
    this.minAmount,
    this.maxAmount,
    this.label = '',
    this.fromAi = false,
  });

  /// Inclusive start, exclusive end.
  final DateTime? from;
  final DateTime? to;
  final Set<TxCategory> categories;

  /// Words matched against merchant, note and M-Pesa code.
  final List<String> terms;
  final TxDirection? direction;
  final double? minAmount;
  final double? maxAmount;

  /// Human summary, e.g. "Transport · last month".
  final String label;
  final bool fromAi;

  bool get isEmpty =>
      from == null && to == null && categories.isEmpty && terms.isEmpty &&
      direction == null && minAmount == null && maxAmount == null;

  /// Categories and words are alternatives ("boda" finds Transport *or* a
  /// merchant called "Boda"); every other condition must hold.
  bool matches(Transaction t) {
    if (from != null && t.occurredAt.isBefore(from!)) return false;
    if (to != null && !t.occurredAt.isBefore(to!)) return false;
    if (direction != null && t.direction != direction) return false;
    if (minAmount != null && t.amount < minAmount!) return false;
    if (maxAmount != null && t.amount > maxAmount!) return false;
    if (categories.isEmpty && terms.isEmpty) return true;
    if (categories.contains(t.category)) return true;
    final haystack = '${t.merchant} ${t.note ?? ''} ${t.reference ?? ''} ${t.category.label}'.toLowerCase();
    return terms.any(haystack.contains);
  }

  SearchFilter copyWith({String? label, bool? fromAi}) => SearchFilter(
        from: from,
        to: to,
        categories: categories,
        terms: terms,
        direction: direction,
        minAmount: minAmount,
        maxAmount: maxAmount,
        label: label ?? this.label,
        fromAi: fromAi ?? this.fromAi,
      );
}

/// Reads everyday phrases offline. Anything it can't read is left to the AI.
abstract final class NaturalSearch {
  static const _synonyms = <String, TxCategory>{
    'boda': TxCategory.transport, 'bodaboda': TxCategory.transport, 'boda-boda': TxCategory.transport,
    'matatu': TxCategory.transport, 'mat': TxCategory.transport, 'fare': TxCategory.transport,
    'fares': TxCategory.transport, 'transport': TxCategory.transport, 'uber': TxCategory.transport,
    'bolt': TxCategory.transport, 'fuel': TxCategory.transport, 'petrol': TxCategory.transport,
    'taxi': TxCategory.transport, 'parking': TxCategory.transport,
    'food': TxCategory.food, 'lunch': TxCategory.food, 'dinner': TxCategory.food,
    'breakfast': TxCategory.food, 'eating': TxCategory.food, 'restaurant': TxCategory.food,
    'restaurants': TxCategory.food, 'takeaway': TxCategory.food, 'dining': TxCategory.food,
    'groceries': TxCategory.groceries, 'grocery': TxCategory.groceries, 'supermarket': TxCategory.groceries,
    'shopping': TxCategory.shopping, 'clothes': TxCategory.shopping,
    'rent': TxCategory.rent, 'house': TxCategory.rent, 'housing': TxCategory.rent,
    'kplc': TxCategory.utilities, 'tokens': TxCategory.utilities, 'electricity': TxCategory.utilities,
    'power': TxCategory.utilities, 'water': TxCategory.utilities, 'wifi': TxCategory.utilities,
    'internet': TxCategory.utilities, 'bills': TxCategory.utilities, 'utilities': TxCategory.utilities,
    'subscriptions': TxCategory.entertainment, 'entertainment': TxCategory.entertainment,
    'betting': TxCategory.entertainment, 'bets': TxCategory.entertainment, 'movies': TxCategory.entertainment,
    'health': TxCategory.health, 'hospital': TxCategory.health, 'pharmacy': TxCategory.health,
    'medicine': TxCategory.health, 'school': TxCategory.education, 'fees': TxCategory.fees,
    'education': TxCategory.education, 'airtime': TxCategory.airtime, 'data': TxCategory.airtime,
    'bundles': TxCategory.airtime, 'savings': TxCategory.savings, 'saved': TxCategory.savings,
    'loan': TxCategory.debt, 'loans': TxCategory.debt, 'debt': TxCategory.debt, 'fuliza': TxCategory.debt,
    'charges': TxCategory.fees, 'salary': TxCategory.income, 'income': TxCategory.income,
  };

  static const _stop = {
    'how', 'much', 'did', 'do', 'i', 'my', 'me', 'on', 'in', 'at', 'for', 'the', 'a', 'an', 'to',
    'what', 'all', 'show', 'spend', 'spent', 'spending', 'paid', 'pay', 'payments', 'sent', 'send',
    'received', 'receive', 'got', 'get', 'from', 'of', 'and', 'with', 'transactions', 'money', 'kes',
    'ksh', 'sh', 'shillings', 'than', 'more', 'less', 'over', 'under', 'above', 'below', 'this',
    'last', 'past', 'week', 'month', 'year', 'today', 'yesterday', 'days', 'day', 'was', 'were',
    'is', 'are', 'there', 'any', 'between', 'since', 'during', 'earned', 'income', 'out', 'ago',
  };

  static const _months = [
    'january', 'february', 'march', 'april', 'may', 'june',
    'july', 'august', 'september', 'october', 'november', 'december',
  ];

  /// Returns null when the query is just a word to look up (plain search).
  static SearchFilter? parse(String query, {DateTime? now}) {
    final today = (now ?? DateTime.now()).dateOnly;
    var q = ' ${query.toLowerCase().replaceAll(RegExp(r'[?!.,]'), ' ')} ';
    DateTime? from;
    DateTime? to;
    String? when;
    TxDirection? direction;
    double? minAmount;
    double? maxAmount;

    void range(DateTime start, DateTime end, String name, String phrase) {
      from = start;
      to = end;
      when = name;
      q = q.replaceFirst(phrase, ' ');
    }

    final tomorrow = today.add(const Duration(days: 1));
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final lastN = RegExp(r' (?:last|past) (\d{1,3}) days? ').firstMatch(q);
    if (lastN != null) {
      final n = int.parse(lastN.group(1)!);
      range(today.subtract(Duration(days: n - 1)), tomorrow, 'last $n days', lastN.group(0)!);
    } else if (q.contains(' today ')) {
      range(today, tomorrow, 'today', ' today ');
    } else if (q.contains(' yesterday ')) {
      range(today.subtract(const Duration(days: 1)), today, 'yesterday', ' yesterday ');
    } else if (q.contains(' this week ')) {
      range(weekStart, tomorrow, 'this week', ' this week ');
    } else if (q.contains(' last week ')) {
      range(weekStart.subtract(const Duration(days: 7)), weekStart, 'last week', ' last week ');
    } else if (q.contains(' this month ')) {
      range(today.monthStart, tomorrow, 'this month', ' this month ');
    } else if (q.contains(' last month ')) {
      final start = DateTime(today.year, today.month - 1);
      range(start, today.monthStart, Fmt.monthName(start), ' last month ');
    } else if (q.contains(' this year ')) {
      range(DateTime(today.year), tomorrow, 'this year', ' this year ');
    } else {
      for (var i = 0; i < 12; i++) {
        final m = RegExp(' (?:in )?(${_months[i]}|${_months[i].substring(0, 3)}) ').firstMatch(q);
        if (m == null) continue;
        // The most recent such month that has started.
        final year = i + 1 > today.month ? today.year - 1 : today.year;
        range(DateTime(year, i + 1), DateTime(year, i + 2), Fmt.monthName(DateTime(year, i + 1)), m.group(0)!);
        break;
      }
    }

    double? money(String s) {
      final m = RegExp(r'^(\d+(?:\.\d+)?)(k)?$').firstMatch(s.replaceAll(',', ''));
      if (m == null) return null;
      return double.parse(m.group(1)!) * (m.group(2) == null ? 1 : 1000);
    }

    final over = RegExp(r' (?:over|above|more than|greater than|at least) (?:kes |ksh )?([\d,.]+k?) ').firstMatch(q);
    if (over != null) {
      minAmount = money(over.group(1)!);
      q = q.replaceFirst(over.group(0)!, ' ');
    }
    final under = RegExp(r' (?:under|below|less than|at most) (?:kes |ksh )?([\d,.]+k?) ').firstMatch(q);
    if (under != null) {
      maxAmount = money(under.group(1)!);
      q = q.replaceFirst(under.group(0)!, ' ');
    }

    if (RegExp(r' (received|receive|got|earned|income|salary|came in) ').hasMatch(q)) {
      direction = TxDirection.inbound;
    } else if (RegExp(r' (spent|spend|paid|pay|sent|send|bought) ').hasMatch(q)) {
      direction = TxDirection.out;
    }

    final categories = <TxCategory>{};
    final terms = <String>[];
    for (final word in q.split(RegExp(r'\s+')).where((w) => w.isNotEmpty)) {
      final cat = _synonyms[word];
      if (cat != null) {
        categories.add(cat);
      } else if (!_stop.contains(word) && word.length >= 2 && money(word) == null) {
        terms.add(word);
      }
    }
    if (categories.contains(TxCategory.income)) direction = TxDirection.inbound;

    final structured = from != null || categories.isNotEmpty || direction != null || minAmount != null || maxAmount != null;
    if (!structured) return null;

    final label = [
      ...categories.map((c) => c.label),
      ...terms.map((t) => '"$t"'),
      ?when,
      if (direction == TxDirection.inbound && !categories.contains(TxCategory.income)) 'money in',
      if (minAmount != null) 'over ${Fmt.kes(minAmount)}',
      if (maxAmount != null) 'under ${Fmt.kes(maxAmount)}',
    ].join(' · ');

    return SearchFilter(
      from: from,
      to: to,
      categories: categories,
      terms: terms,
      direction: direction,
      minAmount: minAmount,
      maxAmount: maxAmount,
      label: label,
    );
  }
}
