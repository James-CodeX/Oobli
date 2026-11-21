import 'package:flutter/foundation.dart';

/// What the user picked as their focus during onboarding.
enum FocusGoal {
  debt('debt', 'Kill the Debt'),
  saving('saving', 'Smart Saving'),
  investing('investing', 'Investment Mode'),
  tracking('tracking', 'Just Tracking');

  const FocusGoal(this.key, this.label);

  final String key;
  final String label;

  static FocusGoal? fromKey(String? key) {
    for (final f in values) {
      if (f.key == key) return f;
    }
    return null;
  }
}

/// The signed-in user plus the preferences stored in their Appwrite account prefs.
@immutable
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.onboardingComplete = false,
    this.smsSyncEnabled = false,
    this.lastSmsSyncAt,
    this.focus,
    this.monthlyIncome,
    this.insightsEnabled = true,
    this.streak = 0,
    this.lastActiveDay,
  });

  final String id;
  final String name;
  final String email;
  final DateTime createdAt;
  final bool onboardingComplete;
  final bool smsSyncEnabled;
  final DateTime? lastSmsSyncAt;
  final FocusGoal? focus;
  final double? monthlyIncome;
  final bool insightsEnabled;
  final int streak;

  /// `yyyy-MM-dd` of the last day the app was opened (for the streak).
  final String? lastActiveDay;

  String get firstName => name.trim().split(' ').first;

  factory UserProfile.fromAccount({
    required String id,
    required String name,
    required String email,
    required String createdAt,
    required Map<String, dynamic> prefs,
  }) =>
      UserProfile(
        id: id,
        name: name.isEmpty ? email.split('@').first : name,
        email: email,
        createdAt: DateTime.parse(createdAt).toLocal(),
        onboardingComplete: prefs['onboardingComplete'] as bool? ?? false,
        smsSyncEnabled: prefs['smsSyncEnabled'] as bool? ?? false,
        lastSmsSyncAt: prefs['lastSmsSyncAt'] == null
            ? null
            : DateTime.tryParse(prefs['lastSmsSyncAt'] as String)?.toLocal(),
        focus: FocusGoal.fromKey(prefs['focus'] as String?),
        monthlyIncome: (prefs['monthlyIncome'] as num?)?.toDouble(),
        insightsEnabled: prefs['insightsEnabled'] as bool? ?? true,
        streak: (prefs['streak'] as num?)?.toInt() ?? 0,
        lastActiveDay: prefs['lastActiveDay'] as String?,
      );

  Map<String, dynamic> toPrefs() => {
        'onboardingComplete': onboardingComplete,
        'smsSyncEnabled': smsSyncEnabled,
        'lastSmsSyncAt': lastSmsSyncAt?.toUtc().toIso8601String(),
        'focus': focus?.key,
        'monthlyIncome': monthlyIncome,
        'insightsEnabled': insightsEnabled,
        'streak': streak,
        'lastActiveDay': lastActiveDay,
      };

  /// Full snapshot for the local session cache.
  Map<String, dynamic> toCache() => {
        'id': id,
        'name': name,
        'email': email,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'prefs': toPrefs(),
      };

  static UserProfile? fromCache(Map<String, dynamic>? json) {
    if (json == null || json['id'] is! String) return null;
    try {
      return UserProfile.fromAccount(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        createdAt: json['createdAt'] as String,
        prefs: Map<String, dynamic>.from(json['prefs'] as Map? ?? const {}),
      );
    } catch (_) {
      return null;
    }
  }

  UserProfile copyWith({
    String? name,
    bool? onboardingComplete,
    bool? smsSyncEnabled,
    DateTime? lastSmsSyncAt,
    FocusGoal? focus,
    double? monthlyIncome,
    bool? insightsEnabled,
    int? streak,
    String? lastActiveDay,
  }) =>
      UserProfile(
        id: id,
        name: name ?? this.name,
        email: email,
        createdAt: createdAt,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        smsSyncEnabled: smsSyncEnabled ?? this.smsSyncEnabled,
        lastSmsSyncAt: lastSmsSyncAt ?? this.lastSmsSyncAt,
        focus: focus ?? this.focus,
        monthlyIncome: monthlyIncome ?? this.monthlyIncome,
        insightsEnabled: insightsEnabled ?? this.insightsEnabled,
        streak: streak ?? this.streak,
        lastActiveDay: lastActiveDay ?? this.lastActiveDay,
      );
}
