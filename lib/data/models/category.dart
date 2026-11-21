import 'package:material_ui/material_ui.dart';

import '../../core/theme/oobli_colors.dart';

/// Spending categories. Keys must match functions/oobli-ai/src/categories.js.
enum TxCategory {
  groceries('groceries', 'Groceries', Icons.shopping_cart_rounded, Tone.success),
  food('food', 'Food & Dining', Icons.restaurant_rounded, Tone.warning),
  transport('transport', 'Transport', Icons.directions_bus_rounded, Tone.info),
  utilities('utilities', 'Utilities', Icons.bolt_rounded, Tone.accent),
  rent('rent', 'Rent & Housing', Icons.home_rounded, Tone.primary),
  shopping('shopping', 'Shopping', Icons.shopping_bag_rounded, Tone.secondary),
  entertainment('entertainment', 'Entertainment', Icons.subscriptions_rounded, Tone.error),
  health('health', 'Health', Icons.local_hospital_rounded, Tone.error),
  education('education', 'Education', Icons.school_rounded, Tone.secondary),
  airtime('airtime', 'Airtime & Data', Icons.phone_android_rounded, Tone.info),
  transfer('transfer', 'Sent to someone', Icons.person_rounded, Tone.warning),
  savings('savings', 'Savings', Icons.savings_rounded, Tone.success),
  debt('debt', 'Debt & Loans', Icons.local_fire_department_rounded, Tone.error),
  fees('fees', 'Fees & Charges', Icons.receipt_long_rounded, Tone.neutral),
  income('income', 'Income', Icons.south_west_rounded, Tone.primary),
  other('other', 'Other', Icons.category_rounded, Tone.neutral);

  const TxCategory(this.key, this.label, this.icon, this.tone);

  final String key;
  final String label;
  final IconData icon;
  final Tone tone;

  static TxCategory fromKey(String? key) =>
      values.firstWhere((c) => c.key == key, orElse: () => TxCategory.other);

  /// Categories a user can pick for money going out.
  static List<TxCategory> get spending =>
      values.where((c) => c != TxCategory.income).toList();

  /// Which plan bucket this category draws from.
  PlanBucket get bucket => switch (this) {
        rent || utilities || groceries || transport || health || education ||
        airtime || fees || debt =>
          PlanBucket.needs,
        savings => PlanBucket.savings,
        income => PlanBucket.none,
        _ => PlanBucket.flex,
      };
}

enum PlanBucket { needs, savings, flex, emergency, none }

/// How the money moved (M-Pesa product or bank).
enum TxChannel {
  pochi('pochi', 'Pochi la Biashara'),
  till('till', 'Merchant Tills'),
  paybill('paybill', 'Paybills'),
  send('send', 'Send Money'),
  withdraw('withdraw', 'Withdrawals'),
  airtime('airtime', 'Airtime'),
  deposit('deposit', 'Deposits'),
  received('received', 'Received'),
  bank('bank', 'Bank'),
  fuliza('fuliza', 'Fuliza'),
  card('card', 'Card'),
  other('other', 'Other');

  const TxChannel(this.key, this.label);

  final String key;
  final String label;

  static TxChannel fromKey(String? key) =>
      values.firstWhere((c) => c.key == key, orElse: () => TxChannel.other);
}

enum TxSource {
  mpesa('mpesa', 'M-Pesa'),
  bank('bank', 'Bank'),
  manual('manual', 'Manual');

  const TxSource(this.key, this.label);

  final String key;
  final String label;

  static TxSource fromKey(String? key) =>
      values.firstWhere((c) => c.key == key, orElse: () => TxSource.manual);
}
