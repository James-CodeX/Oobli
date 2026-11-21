import 'package:flutter/foundation.dart';

import '../../core/theme/oobli_colors.dart';
import 'category.dart';

@immutable
class InsightCard {
  const InsightCard({required this.title, required this.body, required this.tone});

  final String title;
  final String body;
  final Tone tone;

  factory InsightCard.fromJson(Map<String, dynamic> j) => InsightCard(
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        tone: switch (j['tone']) {
          'warning' => Tone.warning,
          'success' => Tone.success,
          'info' => Tone.info,
          _ => Tone.primary,
        },
      );

  Map<String, dynamic> toJson() => {'title': title, 'body': body, 'tone': tone.name};
}

/// A one-tap recategorisation Oobli proposes (Analytics screen).
@immutable
class RecategorizeSuggestion {
  const RecategorizeSuggestion({
    required this.merchant,
    required this.from,
    required this.to,
    required this.body,
  });

  final String merchant;
  final TxCategory from;
  final TxCategory to;
  final String body;

  factory RecategorizeSuggestion.fromJson(Map<String, dynamic> j) => RecategorizeSuggestion(
        merchant: j['merchant'] as String,
        from: TxCategory.fromKey(j['fromCategory'] as String?),
        to: TxCategory.fromKey(j['toCategory'] as String?),
        body: j['body'] as String? ?? '',
      );

  Map<String, dynamic> toJson() =>
      {'merchant': merchant, 'fromCategory': from.key, 'toCategory': to.key, 'body': body};
}

@immutable
class AiInsights {
  const AiInsights({
    required this.headline,
    required this.cards,
    required this.activityNote,
    required this.analyticsNote,
    required this.goalNote,
    this.suggestion,
    this.isFallback = false,
  });

  final String headline;
  final List<InsightCard> cards;
  final String activityNote;
  final String analyticsNote;
  final String goalNote;
  final RecategorizeSuggestion? suggestion;

  /// True when generated on-device because the AI service was unreachable.
  final bool isFallback;

  factory AiInsights.fromJson(Map<String, dynamic> j) => AiInsights(
        headline: j['headline'] as String? ?? '',
        cards: (j['cards'] as List? ?? [])
            .map((e) => InsightCard.fromJson(e as Map<String, dynamic>))
            .toList(),
        activityNote: j['activityNote'] as String? ?? '',
        analyticsNote: j['analyticsNote'] as String? ?? '',
        goalNote: j['goalNote'] as String? ?? '',
        suggestion: j['suggestion'] == null
            ? null
            : RecategorizeSuggestion.fromJson(j['suggestion'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'headline': headline,
        'cards': cards.map((c) => c.toJson()).toList(),
        'activityNote': activityNote,
        'analyticsNote': analyticsNote,
        'goalNote': goalNote,
        'suggestion': suggestion?.toJson(),
      };

  AiInsights withoutSuggestion() => AiInsights(
        headline: headline,
        cards: cards,
        activityNote: activityNote,
        analyticsNote: analyticsNote,
        goalNote: goalNote,
        isFallback: isFallback,
      );
}

@immutable
class WrappedBadge {
  const WrappedBadge({required this.label, required this.icon});

  final String label;

  /// One of: saver, power, streak, star, shield, trend.
  final String icon;
}

@immutable
class WrappedStory {
  const WrappedStory({
    required this.insight,
    required this.badges,
    required this.winTitle,
    required this.winBody,
  });

  final String insight;
  final List<WrappedBadge> badges;
  final String winTitle;
  final String winBody;

  factory WrappedStory.fromJson(Map<String, dynamic> j) => WrappedStory(
        insight: j['insight'] as String? ?? '',
        badges: (j['badges'] as List? ?? [])
            .map((b) => WrappedBadge(
                  label: (b as Map)['label'] as String,
                  icon: b['icon'] as String? ?? 'star',
                ))
            .toList(),
        winTitle: (j['win'] as Map?)?['title'] as String? ?? 'Financial Win!',
        winBody: (j['win'] as Map?)?['body'] as String? ?? '',
      );
}

@immutable
class ChatMessage {
  const ChatMessage({required this.fromUser, required this.text});

  final bool fromUser;
  final String text;

  Map<String, dynamic> toJson() => {'role': fromUser ? 'user' : 'model', 'text': text};
}
