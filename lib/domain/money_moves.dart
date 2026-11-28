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

  /// How close a bank's loan repayment and the M-Pesa payment that funded it
  /// must be.
  static const loanWindow = Duration(hours: 3);

  /// M-Pesa payments that a bank's own message explains, with their fixed
  /// copies. Only unconfirmed transactions change.
  ///
  /// * A bank credit that carries an M-Pesa send's reference ("received in
  ///   a/c ... M-PESA Ref X") proves the user topped up their own account:
  ///   both are own transfers, and certain.
  /// * A bank loan repayment with a same-amount M-Pesa payment to that bank
  ///   shortly before: the bank's message is the repayment, so the M-Pesa
  ///   side only moved the money there. That is a likely answer, so the
  ///   user is asked.
  static List<Transaction> explained(Iterable<Transaction> transactions) {
    final all = transactions.toList();
    final changed = <String, Transaction>{};
    final sends = {
      for (final t in all)
        if (t.source == TxSource.mpesa && t.isOutgoing && t.reference != null) t.reference!: t,
    };
    for (final credit in all) {
      if (credit.source != TxSource.bank || credit.isOutgoing || credit.category != TxCategory.ownTransfer) continue;
      final send = sends[credit.reference];
      if (send == null) continue;
      for (final t in [credit, send]) {
        if (!t.confirmed) {
          changed[t.id] = t.copyWith(category: TxCategory.ownTransfer, aiCategorized: false, confirmed: true);
        }
      }
    }
    for (final repaid in all) {
      if (repaid.source != TxSource.bank || !repaid.isOutgoing || repaid.category != TxCategory.debt) continue;
      final bank = Transaction.merchantKey(repaid.merchant).split(' ').first;
      if (bank.isEmpty) continue;
      for (final t in all) {
        if (t.source != TxSource.mpesa || !t.isOutgoing || t.confirmed) continue;
        if (t.category == TxCategory.ownTransfer || changed.containsKey(t.id)) continue;
        if ((t.amount - repaid.amount).abs() > 1) continue;
        if (t.occurredAt.difference(repaid.occurredAt).abs() > loanWindow) continue;
        if (!Transaction.merchantKey(t.merchant).split(' ').contains(bank)) continue;
        changed[t.id] = t.copyWith(category: TxCategory.ownTransfer, aiCategorized: true, confirmed: false);
        break;
      }
    }
    return changed.values.toList();
  }
}
