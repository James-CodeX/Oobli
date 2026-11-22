import '../data/models/category.dart';
import '../data/models/transaction.dart';

/// Every unsorted transaction from one merchant.
class MerchantGroup {
  const MerchantGroup(this.merchant, this.transactions);

  final String merchant;
  final List<Transaction> transactions;

  String get key => Transaction.merchantKey(merchant);
  int get count => transactions.length;
  double get total => transactions.fold(0, (s, t) => s + t.amount);
}

/// After the user files one merchant, finds others that likely belong in the
/// same category ("Naivas Kilimani" after "Naivas Westlands", other matatu
/// SACCOs after one). The AI widens this; this part is instant and offline.
abstract final class SimilarMerchants {
  /// Words too common in business names to mean anything.
  static const _generic = {
    'ltd', 'limited', 'kenya', 'company', 'enterprises', 'enterprise', 'services', 'service',
    'shop', 'store', 'stores', 'the', 'and', 'agencies', 'agency', 'ventures', 'investments',
    'general', 'traders', 'trading', 'plc', 'group', 'international', 'solutions', 'mpesa',
    'm-pesa', 'pochi', 'biashara', 'till', 'paybill', 'account', 'payment', 'payments', 'merchant',
    'business', 'centre', 'center', 'branch', 'nairobi', 'cash', 'deposit', 'withdrawal',
  };

  static Set<String> keywords(String merchant) => Transaction.merchantKey(merchant)
      .split(' ')
      .where((w) => w.length >= 3 && !_generic.contains(w) && int.tryParse(w) == null)
      .toSet();

  /// Merchants the user could file the same way: same direction, still
  /// unconfirmed, not already in [category], and not [source]'s own merchant.
  static List<MerchantGroup> candidates(Iterable<Transaction> transactions, Transaction source, TxCategory category) {
    final own = Transaction.merchantKey(source.merchant);
    final groups = <String, List<Transaction>>{};
    for (final t in transactions) {
      final key = Transaction.merchantKey(t.merchant);
      if (t.confirmed || t.direction != source.direction || t.category == category || key == own || key.isEmpty) {
        continue;
      }
      if (!category.fits(inbound: !t.isOutgoing)) continue;
      groups.putIfAbsent(key, () => []).add(t);
    }
    return [
      for (final txs in groups.values) MerchantGroup(txs.first.merchant, txs),
    ]..sort((a, b) => b.count.compareTo(a.count));
  }

  /// Candidates sharing a meaningful word with [source]'s merchant.
  static List<MerchantGroup> byName(List<MerchantGroup> candidates, Transaction source) {
    final words = keywords(source.merchant);
    if (words.isEmpty) return const [];
    return candidates.where((g) => keywords(g.merchant).any(words.contains)).toList();
  }
}
