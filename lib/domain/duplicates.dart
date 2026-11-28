import '../data/models/category.dart';
import '../data/models/transaction.dart';

/// One payment that was saved more than once, because several messages told
/// of it (banks often send two for a loan repayment), or because it was read
/// again in a later sync.
class DuplicateGroup {
  const DuplicateGroup(this.keep, this.extra);

  /// The copy that stays: the best reading of the payment.
  final Transaction keep;

  /// The copies to remove.
  final List<Transaction> extra;
}

/// Spots copies of the same loan or savings payment. Matching is on the
/// money itself (same amount, same direction, minutes apart, same lender or
/// savings place), not on how the message was worded or read.
abstract final class Duplicates {
  /// How far apart two messages about one payment can be.
  static const window = Duration(minutes: 5);

  /// Where banks send several messages for one payment.
  static const _kinds = {TxCategory.debt, TxCategory.savings};

  /// Words that name a product, not who holds the money.
  static const _filler = {
    'loan', 'loans', 'mobile', 'mobi', 'bank', 'account', 'savings', 'saving', 'to', 'from', 'the', 'of',
    'for', 'payment', 'repayment', 'm', 'pesa', 'mpesa', 'ltd', 'limited', 'kenya', 'plc', 'advance', 'salary',
  };
  static final _digits = RegExp(r'^\d+$');

  /// The lender, bank or savings place a merchant names: "KCB Mobi Loan" and
  /// "KCB loan" are both {kcb}.
  static Set<String> institution(String merchant) => Transaction.merchantKey(merchant)
      .split(' ')
      .where((w) => w.length >= 2 && !_filler.contains(w) && !_digits.hasMatch(w))
      .toSet();

  /// Whether [a] and [b] are the same payment.
  static bool same(Transaction a, Transaction b) {
    if (a.id == b.id || a.direction != b.direction) return false;
    if ((a.amount - b.amount).abs() >= 0.5) return false;
    if (a.occurredAt.difference(b.occurredAt).abs() > window) return false;
    if (!_kinds.contains(a.category) || !_kinds.contains(b.category)) return false;
    // Every M-Pesa code is its own payment: two codes are two payments.
    final twoCodes = a.source == TxSource.mpesa &&
        b.source == TxSource.mpesa &&
        a.reference != null &&
        b.reference != null &&
        a.reference != b.reference;
    if (twoCodes) return false;
    return institution(a.merchant).intersection(institution(b.merchant)).isNotEmpty;
  }

  /// Groups of copies in [transactions], each with the copy to keep.
  static List<DuplicateGroup> find(Iterable<Transaction> transactions) {
    final candidates = transactions.where((t) => _kinds.contains(t.category)).toList()
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    final groupOf = <String, List<Transaction>>{};
    for (var i = 0; i < candidates.length; i++) {
      final a = candidates[i];
      for (var j = i + 1; j < candidates.length; j++) {
        final b = candidates[j];
        if (b.occurredAt.difference(a.occurredAt) > window) break;
        if (!same(a, b)) continue;
        final ga = groupOf[a.id], gb = groupOf[b.id];
        if (ga == null && gb == null) {
          final g = [a, b];
          groupOf[a.id] = g;
          groupOf[b.id] = g;
        } else if (gb == null) {
          ga!.add(b);
          groupOf[b.id] = ga;
        } else if (ga == null) {
          gb.add(a);
          groupOf[a.id] = gb;
        } else if (!identical(ga, gb)) {
          ga.addAll(gb);
          for (final t in gb) {
            groupOf[t.id] = ga;
          }
        }
      }
    }
    final groups = <List<Transaction>>{for (final g in groupOf.values) g};
    return [
      for (final g in groups)
        () {
          final ranked = [...g]..sort(_better);
          return DuplicateGroup(ranked.first, ranked.skip(1).toList());
        }(),
    ];
  }

  /// Best copy first: one with a transaction code, then one read on the
  /// phone (not guessed by the AI), then the earliest.
  static int _better(Transaction a, Transaction b) {
    int score(Transaction t) => (t.reference != null ? 2 : 0) + (t.aiCategorized ? 0 : 1);
    final byScore = score(b) - score(a);
    if (byScore != 0) return byScore;
    final byTime = a.occurredAt.compareTo(b.occurredAt);
    return byTime != 0 ? byTime : a.id.compareTo(b.id);
  }
}
