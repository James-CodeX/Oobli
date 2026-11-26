import 'package:flutter/foundation.dart';

import 'category.dart';

enum TxDirection { out, inbound }

@immutable
class Transaction {
  const Transaction({
    required this.id,
    required this.fingerprint,
    required this.amount,
    required this.direction,
    required this.merchant,
    required this.category,
    required this.channel,
    required this.source,
    required this.occurredAt,
    this.reference,
    this.rawMessage,
    this.aiCategorized = false,
    this.confirmed = false,
    this.note,
    this.balance,
    this.deleted = false,
  });

  final String id;
  final String fingerprint;
  final double amount;
  final TxDirection direction;
  final String merchant;
  final TxCategory category;
  final TxChannel channel;
  final TxSource source;
  final DateTime occurredAt;
  final String? reference;
  final String? rawMessage;
  final bool aiCategorized;
  final bool confirmed;
  final String? note;
  final double? balance;

  /// Deleted on some device; kept as a tombstone so other devices' delta
  /// syncs learn about it. Never shown.
  final bool deleted;

  bool get isOutgoing => direction == TxDirection.out;

  /// Money that counts as spending (excludes moving money into savings or
  /// between the user's own accounts).
  bool get isSpend => isOutgoing && category != TxCategory.savings && category != TxCategory.ownTransfer;

  /// Needs the user's confirmation: AI picked the category and nobody checked it.
  bool get needsReview => aiCategorized && !confirmed;

  factory Transaction.fromRow(String id, Map<String, dynamic> d) => Transaction(
        id: id,
        fingerprint: d['fingerprint'] as String,
        amount: (d['amount'] as num).toDouble(),
        direction: d['direction'] == 'in' ? TxDirection.inbound : TxDirection.out,
        merchant: d['merchant'] as String,
        category: TxCategory.fromKey(d['category'] as String?),
        channel: TxChannel.fromKey(d['channel'] as String?),
        source: TxSource.fromKey(d['source'] as String?),
        occurredAt: DateTime.parse(d['occurredAt'] as String).toLocal(),
        reference: d['reference'] as String?,
        rawMessage: d['rawMessage'] as String?,
        aiCategorized: d['aiCategorized'] as bool? ?? false,
        confirmed: d['confirmed'] as bool? ?? false,
        note: d['note'] as String?,
        balance: (d['balance'] as num?)?.toDouble(),
        deleted: d['deleted'] == true,
      );

  /// The on-device cache form: the row plus its id.
  Map<String, dynamic> toJson() => {
        'id': id,
        ...toRow(''),
        if (deleted) 'deleted': true,
      }..remove('userId');

  factory Transaction.fromJson(Map<String, dynamic> j) => Transaction.fromRow(j['id'] as String, j);

  /// This transaction with [patch] (row fields, as sent to Appwrite) applied.
  Transaction applyPatch(Map<String, dynamic> patch) => Transaction.fromJson({...toJson(), ...patch});

  Map<String, dynamic> toRow(String userId) => {
        'userId': userId,
        'fingerprint': fingerprint,
        'amount': amount,
        'direction': isOutgoing ? 'out' : 'in',
        'merchant': merchant,
        'category': category.key,
        'channel': channel.key,
        'source': source.key,
        'occurredAt': occurredAt.toUtc().toIso8601String(),
        'reference': reference,
        'rawMessage': rawMessage,
        'aiCategorized': aiCategorized,
        'confirmed': confirmed,
        'note': note,
        'balance': balance,
      };

  Transaction copyWith({
    String? id,
    double? amount,
    TxDirection? direction,
    String? merchant,
    TxCategory? category,
    TxChannel? channel,
    DateTime? occurredAt,
    bool? aiCategorized,
    bool? confirmed,
    String? note,
  }) =>
      Transaction(
        id: id ?? this.id,
        fingerprint: fingerprint,
        amount: amount ?? this.amount,
        direction: direction ?? this.direction,
        merchant: merchant ?? this.merchant,
        category: category ?? this.category,
        channel: channel ?? this.channel,
        source: source,
        occurredAt: occurredAt ?? this.occurredAt,
        reference: reference,
        rawMessage: rawMessage,
        aiCategorized: aiCategorized ?? this.aiCategorized,
        confirmed: confirmed ?? this.confirmed,
        note: note ?? this.note,
        balance: balance,
      );

  /// Normalised merchant key used for learned category rules.
  static String merchantKey(String merchant) => merchant
      .toLowerCase()
      .replaceAll(RegExp(r'\b(0|\+?254)\d{9}\b'), '')
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
