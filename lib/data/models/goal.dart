import 'package:material_ui/material_ui.dart';

import '../../core/theme/oobli_colors.dart';

/// Icons a goal can use (stored by key so they survive app updates).
enum GoalIcon {
  laptop('laptop', Icons.laptop_mac_rounded),
  phone('phone', Icons.phone_iphone_rounded),
  travel('travel', Icons.flight_takeoff_rounded),
  emergency('emergency', Icons.emergency_rounded),
  home('home', Icons.home_rounded),
  car('car', Icons.directions_car_rounded),
  school('school', Icons.school_rounded),
  gift('gift', Icons.card_giftcard_rounded),
  business('business', Icons.storefront_rounded),
  star('star', Icons.star_rounded);

  const GoalIcon(this.key, this.icon);

  final String key;
  final IconData icon;

  static GoalIcon fromKey(String? key) =>
      values.firstWhere((g) => g.key == key, orElse: () => GoalIcon.star);
}

@immutable
class Milestone {
  const Milestone({required this.label, required this.date, required this.completed});

  final String label;
  final String date;
  final bool completed;
}

@immutable
class Goal {
  const Goal({
    required this.id,
    required this.title,
    required this.icon,
    required this.target,
    required this.saved,
    required this.createdAt,
    this.deadline,
    this.isPrimary = false,
    this.tone = Tone.primary,
  });

  final String id;
  final String title;
  final GoalIcon icon;
  final double target;
  final double saved;
  final DateTime createdAt;
  final DateTime? deadline;
  final bool isPrimary;
  final Tone tone;

  double get progress => target <= 0 ? 0 : (saved / target).clamp(0, 1).toDouble();
  double get remaining => (target - saved).clamp(0, double.infinity).toDouble();
  bool get isComplete => saved >= target && target > 0;

  factory Goal.fromRow(String id, String createdAt, Map<String, dynamic> d) => Goal(
        id: id,
        title: d['title'] as String,
        icon: GoalIcon.fromKey(d['icon'] as String?),
        target: (d['target'] as num).toDouble(),
        saved: (d['saved'] as num? ?? 0).toDouble(),
        createdAt: DateTime.parse(createdAt).toLocal(),
        deadline: d['deadline'] == null ? null : DateTime.parse(d['deadline'] as String).toLocal(),
        isPrimary: d['isPrimary'] as bool? ?? false,
        tone: Tone.values.firstWhere((t) => t.name == d['tone'], orElse: () => Tone.primary),
      );

  Map<String, dynamic> toRow(String userId) => {
        'userId': userId,
        'title': title,
        'icon': icon.key,
        'target': target,
        'saved': saved,
        'deadline': deadline?.toUtc().toIso8601String(),
        'isPrimary': isPrimary,
        'tone': tone.name,
      };

  Goal copyWith({
    String? title,
    GoalIcon? icon,
    double? target,
    double? saved,
    DateTime? deadline,
    bool clearDeadline = false,
    bool? isPrimary,
    Tone? tone,
  }) =>
      Goal(
        id: id,
        title: title ?? this.title,
        icon: icon ?? this.icon,
        target: target ?? this.target,
        saved: saved ?? this.saved,
        createdAt: createdAt,
        deadline: clearDeadline ? null : deadline ?? this.deadline,
        isPrimary: isPrimary ?? this.isPrimary,
        tone: tone ?? this.tone,
      );
}
