import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/theme/oobli_colors.dart';
import 'category.dart';

enum PlanStatus { draft, active }

@immutable
class PlanAllocation {
  const PlanAllocation({
    required this.bucket,
    required this.label,
    required this.percent,
    required this.amount,
    required this.reason,
  });

  final PlanBucket bucket;
  final String label;
  final int percent;
  final double amount;
  final String reason;

  Tone get tone => switch (bucket) {
        PlanBucket.needs => Tone.primary,
        PlanBucket.savings => Tone.secondary,
        PlanBucket.flex => Tone.accent,
        _ => Tone.warning,
      };

  /// Short label for chart legends (design: Needs / Savings / Wants / Emergency).
  String get legend => switch (bucket) {
        PlanBucket.needs => 'Needs',
        PlanBucket.savings => 'Savings',
        PlanBucket.flex => 'Wants',
        _ => 'Emergency',
      };

  factory PlanAllocation.fromJson(Map<String, dynamic> j) => PlanAllocation(
        bucket: PlanBucket.values.firstWhere(
          (b) => b.name == j['key'],
          orElse: () => PlanBucket.emergency,
        ),
        label: j['label'] as String? ?? '',
        percent: (j['percent'] as num).round(),
        amount: (j['amount'] as num).toDouble(),
        reason: j['reason'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'key': bucket.name,
        'label': label,
        'percent': percent,
        'amount': amount,
        'reason': reason,
      };

  PlanAllocation withPercent(int newPercent, double income) => PlanAllocation(
        bucket: bucket,
        label: label,
        percent: newPercent,
        amount: (income * newPercent / 100).roundToDouble(),
        reason: reason,
      );
}

@immutable
class Plan {
  const Plan({
    required this.id,
    required this.month,
    required this.income,
    required this.status,
    required this.allocations,
    this.goal,
    this.focus,
    this.summary,
  });

  final String id;

  /// `yyyy-MM`.
  final String month;
  final double income;
  final PlanStatus status;
  final List<PlanAllocation> allocations;
  final String? goal;
  final String? focus;
  final String? summary;

  bool get isActive => status == PlanStatus.active;

  PlanAllocation? allocationFor(PlanBucket bucket) {
    for (final a in allocations) {
      if (a.bucket == bucket) return a;
    }
    return null;
  }

  factory Plan.fromRow(String id, Map<String, dynamic> d) => Plan(
        id: id,
        month: d['month'] as String,
        income: (d['income'] as num).toDouble(),
        status: d['status'] == 'active' ? PlanStatus.active : PlanStatus.draft,
        allocations: (jsonDecode(d['allocations'] as String) as List)
            .map((e) => PlanAllocation.fromJson(e as Map<String, dynamic>))
            .toList(),
        goal: d['goal'] as String?,
        focus: d['focus'] as String?,
        summary: d['summary'] as String?,
      );

  Map<String, dynamic> toRow(String userId) => {
        'userId': userId,
        'month': month,
        'income': income,
        'status': status.name,
        'allocations': jsonEncode(allocations.map((a) => a.toJson()).toList()),
        'goal': goal,
        'focus': focus,
        'summary': summary,
      };

  Plan copyWith({PlanStatus? status, List<PlanAllocation>? allocations, double? income}) => Plan(
        id: id,
        month: month,
        income: income ?? this.income,
        status: status ?? this.status,
        allocations: allocations ?? this.allocations,
        goal: goal,
        focus: focus,
        summary: summary,
      );
}
