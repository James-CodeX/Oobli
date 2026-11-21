import '../models/category.dart';
import '../models/transaction.dart';

/// Fast, offline category guesses for well-known Kenyan merchants. Anything
/// this cannot place confidently is left for the AI categoriser.
abstract final class KeywordCategorizer {
  static final _rules = <TxCategory, RegExp>{
    TxCategory.groceries: _r(r'naivas|carrefour|quick ?mart|chandarana|magunas|cleanshelf|'
        r'uchumi|eastmatt|mama mboga|greengrocer|grocer|butchery|supermarket|mini ?mart|'
        r'fruits|vegetables|green ?market'),
    TxCategory.food: _r(r'\bjava\b|kfc|chicken inn|pizza|artcaffe|\bcafe\b|cafeteria|restaurant|'
        r'glovo|uber eats|bolt food|kibandaski|eatery|bakery|galitos|burger|subway|'
        r'big square|cj.?s|kukito'),
    TxCategory.transport: _r(r'\buber\b|\bbolt\b|little cab|faras|super metro|metro trans|'
        r'\bshell\b|totalenergies|\brubis\b|ola energy|petrol|\bfuel\b|parking|\bsgr\b|'
        r'easy coach|matatu|madaraka express|buupass|kenya railways'),
    TxCategory.utilities: _r(r'kplc|kenya power|nairobi water|ncwsc|\bzuku\b|safaricom home|'
        r'faiba|\bdstv\b|\bgotv\b|startimes|multichoice|water ?co|k-?gas|pro ?gas|'
        r'internet|wi-?fi|safaricom fibre'),
    TxCategory.rent: _r(r'\brent\b|landlord|apartments|properties|property mgt|housing'),
    TxCategory.shopping: _r(r'jumia|kilimall|masoko|fashion|clothing|electronics|hotpoint|'
        r'hardware|appliances|\bmall\b|boutique|textile'),
    TxCategory.entertainment: _r(r'netflix|spotify|showmax|youtube|apple\.com|google play|'
        r'sportpesa|betika|odibets|mozzart|betway|cinema|imax|playstation|steam'),
    TxCategory.health: _r(r'pharmacy|chemist|hospital|clinic|medical|\bnhif\b|\bsha\b|'
        r'social health|aga khan|mp shah|goodlife|dental|optic'),
    TxCategory.education: _r(r'school|academy|college|university|\bhelb\b|tuition|kcse'),
    TxCategory.savings: _r(r'm-?shwari|m-?mali|money market|\bmmf\b|ziidi|cic asset|'
        r'\bsacco\b|britam unit'),
    TxCategory.debt: _r(r'fuliza|kcb m-?pesa|\btala\b|\bbranch\b|zenka|okash|hustler fund|'
        r'\bloan\b'),
    TxCategory.airtime: _r(r'airtime|bundles?|safaricom data'),
  };

  static RegExp _r(String pattern) => RegExp(pattern, caseSensitive: false);

  /// Returns a category, or `null` when the AI should decide.
  static TxCategory? categorize({
    required String merchant,
    required TxChannel channel,
    required TxDirection direction,
  }) {
    if (direction == TxDirection.inbound) return TxCategory.income;
    if (channel == TxChannel.airtime) return TxCategory.airtime;
    for (final entry in _rules.entries) {
      if (entry.value.hasMatch(merchant)) return entry.key;
    }
    return null;
  }
}
