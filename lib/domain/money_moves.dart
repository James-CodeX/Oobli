import '../data/models/category.dart';
import '../data/models/transaction.dart';

/// Money that went out and came straight back (or the reverse): a refund, a
/// friend returning cash, a reversed payment. Neither side is real spending
/// or income.
class MoneyMove {
  const MoneyMove(this.first, this.second);

  final Transaction first;
  final Transaction second;

  List<Transaction> get both => [first, second];
}

/// Spots the user moving their own money, so it doesn't inflate spending or
/// income: sending to themselves, and out-and-back round trips.
abstract final class MoneyMoves {
  /// How far apart the two halves of a round trip can be.
  static const window = Duration(hours: 72);

  /// Categories that already describe the movement and must be kept.
  static const _meaningful = {
    TxCategory.ownTransfer,
    TxCategory.savings,
    TxCategory.debt,
    TxCategory.bankWithdrawal,
  };

  /// Whether [merchant] is the account owner, e.g. Send Money to your own
  /// second line. Needs two matching names: one name alone is too common.
  static bool isOwner(String merchant, String? ownerName) {
    if (ownerName == null || ownerName.trim().isEmpty) return false;
    final mine = _names(ownerName);
    if (mine.length < 2) return false;
    final theirs = _names(merchant);
    return mine.where(theirs.contains).length >= 2;
  }

  static Set<String> _names(String s) =>
      Transaction.merchantKey(s).split(' ').where((w) => w.length >= 2 && !_digits.hasMatch(w)).toSet();
  static final _digits = RegExp(r'^\d+$');

  /// Out-and-back pairs: same counterparty, same amount, opposite directions,
  /// within [window]. Only unconfirmed transactions are paired, so anything
  /// the user already decided stays as it is. Each transaction pairs once.
  static List<MoneyMove> roundTrips(Iterable<Transaction> transactions) {
    final candidates = transactions
        .where((t) =>
            !t.confirmed &&
            !_meaningful.contains(t.category) &&
            t.channel != TxChannel.withdraw &&
            t.channel != TxChannel.deposit &&
            Transaction.merchantKey(t.merchant).isNotEmpty)
        .toList()
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

    final used = <String>{};
    final moves = <MoneyMove>[];
    for (var i = 0; i < candidates.length; i++) {
      final a = candidates[i];
      if (used.contains(a.id)) continue;
      final key = Transaction.merchantKey(a.merchant);
      for (var j = i + 1; j < candidates.length; j++) {
        final b = candidates[j];
        if (b.occurredAt.difference(a.occurredAt) > window) break;
        if (used.contains(b.id) || b.direction == a.direction) continue;
        if ((b.amount - a.amount).abs() > 1) continue;
        if (Transaction.merchantKey(b.merchant) != key) continue;
        used
          ..add(a.id)
          ..add(b.id);
        moves.add(MoneyMove(a, b));
        break;
      }
    }
    return moves;
  }
}
