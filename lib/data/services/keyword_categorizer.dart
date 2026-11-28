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

  /// Money received from a bank is the user moving their own money into
  /// M-Pesa, not income. "Bulk account" senders are left to the AI: employers
  /// pay salaries through them too.
  static final _bank = _r(r'\bbank\b|\bequity\b|\bkcb\b(?! ?m-?pesa)|co-?op(erative)?|\bncba\b|'
      r'\babsa\b|stanbic|stan ?chart|standard chartered|\bi ?& ?m\b|\bdtb\b|diamond trust|'
      r'family bank|sidian|\bhf ?group\b|housing finance|gulf african|\bnbk\b|\bboa\b|'
      r'credit bank|\bloop\b|pesalink|prime bank|\bpostbank\b');
  static final _loanIn = _r(r'fuliza|kcb m-?pesa|\btala\b|\bbranch\b|zenka|okash|hustler fund|'
      r'\bloan\b|m-?shwari loan');
  static final _savingsIn = _r(r'm-?shwari|m-?mali|money market|\bmmf\b|ziidi|\bsacco\b');
  static final _bulk = _r(r'bulk|b2c|disburse');

  /// Places that hold savings and also lend: only the message says which.
  static final _savesAndLends = _r(r'm-?shwari|kcb m-?pesa');
  static final _loanWords = _r(r'\bloans?\b(?! limit)|repay|salary advance|overdue');

  /// Whether a message (or merchant) is about a loan rather than savings.
  static bool mentionsLoan(String text) => _loanWords.hasMatch(text);

  /// Savings or loan for [merchant], from the words in it and its message
  /// [text]; `null` when nothing says (the AI then reads the message).
  static TxCategory? _savingsOrLoan(String merchant, String? text) {
    if (mentionsLoan('$merchant ${text ?? ''}')) return TxCategory.debt;
    // M-Shwari moves without loan words are savings; KCB M-Pesa is unclear.
    return _r(r'm-?shwari').hasMatch(merchant) ? TxCategory.savings : null;
  }

  static RegExp _r(String pattern) => RegExp(pattern, caseSensitive: false);

  /// Returns a category, or `null` when the AI should decide. [text] is the
  /// original message, when there is one.
  static TxCategory? categorize({
    required String merchant,
    required TxChannel channel,
    required TxDirection direction,
    String? text,
  }) {
    if (_savesAndLends.hasMatch(merchant)) return _savingsOrLoan(merchant, text);
    if (direction == TxDirection.inbound) return _receiving(merchant);
    if (channel == TxChannel.airtime) return TxCategory.airtime;
    for (final entry in _rules.entries) {
      if (entry.value.hasMatch(merchant)) return entry.key;
    }
    return null;
  }

  static TxCategory? _receiving(String sender) {
    if (_loanIn.hasMatch(sender)) return TxCategory.debt;
    if (_savingsIn.hasMatch(sender)) return TxCategory.savings;
    if (_bulk.hasMatch(sender)) return null; // salary or bank app transfer: AI decides
    if (_bank.hasMatch(sender)) return TxCategory.bankWithdrawal;
    return null;
  }
}
